import { execSync } from 'child_process';
import { stripAnsi } from '../utils/ansi.js';
import { logger } from './logger.js';
export class TmuxClient {
    exec(command) {
        try {
            // Usa -L bigide-{project} se necessario, ma qui assumiamo che la sessione tmux sia attiva
            // e il comando venga eseguito nel contesto giusto.
            // Se l'agente è dentro la sessione, tmux comandi funzionano direttamente.
            // Se l'agente è esterno, dovremmo passare -S socket o -t session.
            // Assunzione: L'agente gira come child process di Claude Code dentro il terminale.
            // I comandi `tmux` ereditano la socket se `TMUX` env var è settata.
            const output = execSync(`tmux ${command}`, { encoding: 'utf-8', stdio: ['ignore', 'pipe', 'pipe'] });
            return output;
        }
        catch (error) {
            const msg = error.stderr ? error.stderr.toString().trim() : error.message;
            logger.error(`Tmux command failed: tmux ${command}`, { error: msg });
            throw new Error(`TMUX_ERROR: ${msg}`);
        }
    }
    capturePane(target, lines = 50) {
        // -p: print to stdout, -J: join wrapped lines (utile per output pulito), -S: start line (negative = from bottom)
        // Se lines è positivo, prendiamo le ultime N righe.
        const startLine = -Math.abs(lines);
        // Usa -t target per specificare il pane
        return this.exec(`capture-pane -p -J -S ${startLine} -t "${target}"`);
    }
    sendKeys(target, command) {
        // Invia i tasti. Se command finisce con newline, viene eseguito.
        // Se command è una stringa complessa, meglio inviare come tasti letterali (-l non supporta tutti i caratteri speciali bene,
        // ma per comandi shell è ok).
        // Nota: send-keys non ha output su stdout.
        this.exec(`send-keys -t "${target}" "${command}" Enter`);
    }
    listPanes(session) {
        // Format personalizzato per parsing facile
        // window_index.pane_index: pane_id [widthxheight] (active?) command
        const format = '#{window_index}.#{pane_index}: #{pane_id} [#{pane_width}x#{pane_height}] #{?pane_active,(active),} #{pane_current_command}';
        const target = session ? `-t "${session}"` : '';
        return this.exec(`list-panes -a ${target} -F "${format}"`);
    }
    // Helper per wait-for-prompt
    async waitForPrompt(target, promptRegex, timeoutMs = 5000) {
        const start = Date.now();
        while (Date.now() - start < timeoutMs) {
            try {
                const content = this.capturePane(target, 50); // Cattura ultime 50 righe
                const cleanContent = stripAnsi(content);
                if (promptRegex.test(cleanContent)) {
                    return cleanContent;
                }
            }
            catch (e) {
                // Ignora errori temporanei di capture
            }
            await new Promise(resolve => setTimeout(resolve, 200)); // Poll ogni 200ms
        }
        throw new Error(`TIMEOUT: Prompt not found in ${target} after ${timeoutMs}ms`);
    }
    splitWindow(target, direction = 'h', size) {
        const flag = direction === 'h' ? '-h' : '-v';
        const sizeFlag = size ? `-l ${size}` : '';
        // -P -F '#{pane_id}' returns the new pane ID
        return this.exec(`split-window ${flag} ${sizeFlag} -t "${target}" -P -F "#{pane_id}"`).trim();
    }
    killPane(target) {
        this.exec(`kill-pane -t "${target}"`);
    }
    resizePane(target, direction, amount = 5) {
        this.exec(`resize-pane -t "${target}" -${direction} ${amount}`);
    }
}
