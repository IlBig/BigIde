# tmux-mcp IDE — Specifica Completa di Progetto

## Documento di Riferimento per Architettura e Sviluppo

**Versione:** 1.0
**Data:** 19 Febbraio 2026
**Stato:** Bozza approvata — pronta per fase architetturale BMAD

---

## 1. Visione del Progetto

### 1.1 Cosa è tmux-mcp IDE

Un ambiente di sviluppo completo orchestrato da terminale, costruito su **tmux** e **Ghostty**, dove **Claude Code** è il motore principale di sviluppo e ha accesso e controllo su tutti i pannelli tramite un **MCP server dedicato**.

Non è un IDE tradizionale. È un **workspace programmabile** dove l'agente AI (Claude Code) può leggere l'output di qualsiasi pannello, inviare comandi a qualsiasi processo, monitorare build e log, e orchestrare l'intero flusso di sviluppo — tutto dal terminale.

### 1.2 Obiettivi Primari

1. **Claude Code al centro**: l'agente AI ha visibilità e controllo su tutti i pannelli tramite MCP
2. **Multi-progetto**: ogni tab tmux è un progetto separato con contesto indipendente
3. **Zero dipendenze invasive**: niente tiling WM, niente modifiche al sistema — solo tmux, Ghostty, e script
4. **Ergonomia da terminale**: keybinding coerenti, layout stabile, informazioni sempre visibili
5. **Estensibilità**: architettura modulare che permette di aggiungere pannelli e tool nel tempo

### 1.3 Sistema Host

| Componente | Scelta |
|---|---|
| OS | macOS (Apple Silicon) |
| Terminale | Ghostty |
| Shell | zsh (compatibile fish) |
| Multiplexer | tmux ≥ 3.3 |
| AI Agent | Claude Code (Node.js CLI) |
| Abbonamento | Claude Max (Max5 o Max20) |

---

## 2. Architettura del Layout

### 2.1 Struttura Generale

Ogni **tab tmux** rappresenta un **progetto**. Il nome del tab corrisponde al nome del progetto. Si può lavorare su più progetti contemporaneamente switchando tra tab.

Ogni tab ha la stessa struttura di pannelli:

```
┌─[Prg1]─[Prg2]─[Prg3]──────── CPU:23% │ RAM:67% │ 19/02 07:37─┐
│              STATUS BAR SUPERIORE                               │
├──────────────┬─────────────────────────────────────────────────-┤
│              │                                                  │
│  FILE        │          CLAUDE CODE                             │
│  BROWSER     │          (pannello principale)                   │
│  (Yazi)      │                                                  │
│              │                                                  │
│  ~25%        │          ~75%                                    │
│              │                                                  │
│              │                                                  │
├──────┬───────┴──────────┬──────────────────────────────────────-┤
│USAGE │      LOG         │        TERMINALE                      │
│(mon) │                  │                                       │
│      │                  │                                       │
├──────┴──────────────────┴──────────────────────────────────────-┤
│ 🔀 main │ ✓ clean │ abc1234 "fix auth" │ +2 -1    [GIT BAR]   │
└────────────────────────────────────────────────────────────────-┘
```

### 2.2 Stato con Perplexity Attivato (toggle prefix+p)

```
├──────────────┬──────────────────────┬──────────────────────────┤
│              │                      │                          │
│  FILE        │   CLAUDE CODE       │   PERPLEXITY             │
│  BROWSER     │                      │   (ricerca attiva)       │
│  (Yazi)      │                      │                          │
│              │   ~37.5%             │   ~37.5%                 │
│              │                      │                          │
├──────┬───────┴──────────┬───────────┴──────────────────────────┤
│USAGE │      LOG         │        TERMINALE                      │
```

Il pannello Perplexity appare/scompare con `prefix + p`. Quando attivo, divide verticalmente lo spazio di Claude Code al 50%. Quando chiuso, Claude Code torna al 75%.

### 2.3 Stato con Browser Esterno (Chrome)

Al primo avvio del browser nella sessione, un dialog AppleScript chiede:

**Opzione A — 50/50:**
```
┌─────────────────────────┬─────────────────────────┐
│                         │                         │
│      GHOSTTY            │      CHROME             │
│      (tmux IDE)         │      (preview/docs)     │
│                         │                         │
│      50% schermo        │      50% schermo        │
│                         │                         │
└─────────────────────────┴─────────────────────────┘
```

**Opzione B — Entrambi fullscreen:**
Ghostty fullscreen + Chrome fullscreen (su space separati o stessa area, switch con Cmd+Tab).

La scelta viene salvata per la sessione corrente.

### 2.4 Proporzioni dei Pannelli

| Pannello | Larghezza | Altezza | Note |
|---|---|---|---|
| File Browser (Yazi) | 25% | 70% (area superiore) | Colonna sinistra fissa |
| Claude Code | 75% | 70% (area superiore) | Pannello dominante |
| Usage Monitor | 15% | 30% (area inferiore) | Angolo basso-sinistra |
| Log | 35% | 30% (area inferiore) | Centro basso |
| Terminale | 50% | 30% (area inferiore) | Destra basso |
| Status bar top | 100% | 1 riga | tmux status-left/right |
| Git bar bottom | 100% | 1 riga | tmux status bar inferiore |

---

## 3. Descrizione dei Pannelli

### 3.1 File Browser — Yazi

**Tool:** Yazi (Rust)
**Ruolo:** Navigazione file system del progetto con anteprime

**Funzionalità richieste:**
- Navigazione da tastiera e mouse
- Doppio click / Enter su file → apre LazyVim in overlay
- Anteprime immagini native via Kitty Graphics Protocol (supportato da Ghostty)
- Anteprime file Office/PDF via Quick Look macOS (custom previewer)
- Anteprime video via ffmpegthumbnailer

**Integrazione Quick Look per anteprime:**
Yazi supporta custom previewer tramite script shell. Il flusso:
1. Yazi passa il path del file allo script `ql-preview.sh`
2. Lo script chiama `qlmanage -t -s 800 -o /tmp/yazi-previews/ "$FILE_PATH"`
3. `qlmanage` genera un thumbnail PNG
4. Lo script restituisce il path dell'immagine
5. Yazi renderizza il PNG nel pannello preview via Kitty graphics protocol

**Formati supportati da Quick Look macOS:** PDF, DOC/DOCX, XLS/XLSX, PPT/PPTX, Pages, Numbers, Keynote, immagini (tutti), video (frame preview), audio (waveform), Markdown, codice sorgente.

**Criticità note:**
- Il doppio click attraverso la catena Ghostty→tmux→Yazi potrebbe richiedere tuning
- `qlmanage -t` genera thumbnail statiche (una pagina). Per preview multi-pagina: `qlmanage -p` apre Quick Look nativo come finestra floating
- Installazione: `brew install yazi ffmpegthumbnailer`

### 3.2 Claude Code — Pannello Principale

**Tool:** Claude Code (CLI Node.js di Anthropic)
**Ruolo:** Agente di sviluppo AI, centro di controllo

Claude Code gira come processo interattivo nel pannello principale. Ha accesso all'MCP server tmux-mcp che gli permette di:
- Leggere l'output di qualsiasi altro pannello
- Inviare comandi a qualsiasi pannello
- Creare/distruggere pannelli dinamicamente
- Monitorare build, test, log in tempo reale

**Configurazione MCP:** il server tmux-mcp viene registrato in `~/.claude/settings.json` (o nel file di configurazione del progetto) come MCP server con trasporto stdio.

**Multi-progetto:** ogni tab tmux ha la propria istanza Claude Code nella directory del progetto corrispondente. Attenzione: più istanze = più consumo abbonamento.

### 3.3 Usage Monitor — Claude Code Usage Monitor

**Tool:** claude-monitor (PyPI: `claude-monitor`)
**Repo:** https://github.com/Maciek-roboblog/Claude-Code-Usage-Monitor
**Versione:** v3.1.0+ (attiva, 6.5k stelle, MIT)

**Cosa fa:**
- Legge direttamente i file di sessione di Claude Code (`~/.config/claude`)
- Calcola consumo token in tempo reale
- Stima burn rate con algoritmi ML (P90, 90° percentile)
- Mostra progress bar colorate con Rich UI
- Supporta piani: Pro (19k token), Max5 (88k), Max20 (220k), Custom
- Predizioni intelligenti su quando si esaurirà la sessione
- Analisi costi per modello

**Comando nel pannello:**
```bash
claude-monitor --plan max5 --theme dark --refresh-rate 10
```

**Installazione:** `uv tool install claude-monitor`

**Per la status bar superiore (post-MVP):** si potrebbe creare un piccolo script che legge gli stessi file di sessione e produce un indicatore sintetico tipo `CC: 45% ▓▓▓░░` per la riga di stato tmux.

### 3.4 Terminale Interattivo

Shell standard (zsh) per comandi manuali. Nessuna complessità particolare.

Il terminale è anche il target di alcuni comandi MCP (es. `git push` dal keybinding git viene eseguito qui e l'output è visibile).

### 3.5 Pannello Log

**Tool:** `tail -f` (base) / `lnav` (avanzato) / `multitail` (multi-file)

Mostra l'output continuo dei processi in esecuzione: dev server, build, test runner, ecc.

**Opzioni di implementazione:**
- MVP: `tail -f /path/to/logfile`
- Avanzato: `lnav` per log strutturati con syntax highlighting, filtraggio, e ricerca
- Multi-source: `multitail` per seguire più log con colori diversi

Il pannello può essere configurato dallo script di bootstrap per puntare ai log del framework in uso (Next.js, Vite, ecc.).

### 3.6 Perplexity — Pannello Toggle

**Tool:** perplexity-cli
**Repo:** https://github.com/dawid-szewc/perplexity-cli
**Versione:** v1.0.0 (MIT, Python singolo file)

**Cosa fa:** client CLI per Perplexity API. Invia domande, riceve risposte formattate con citazioni e statistiche token.

**Requisiti:**
- API key Perplexity (piano API separato, pagamento a consumo)
- Python 3.6+
- Variabile ambiente: `PERPLEXITY_API_KEY`

**Installazione:**
```bash
curl -s https://raw.githubusercontent.com/dawid-szewc/perplexity-cli/main/perplexity.py > ~/.local/bin/perplexity
chmod +x ~/.local/bin/perplexity
```

**Uso nel pannello:**
```bash
perplexity -uc -m sonar-pro "domanda"
```

**Opzioni utili:** `-u` mostra usage token, `-c` mostra citazioni, `-g` formattazione Glow per markdown.

**Toggle:** keybinding `prefix + p`:
- Se il pannello non esiste → split verticale di Claude Code al 50%, lancia wrapper interattivo Perplexity
- Se il pannello esiste → `tmux kill-pane`, Claude Code torna a 75%

**Integrazione MCP (post-MVP):** il tool `toggle_perplexity` nell'MCP server permette a Claude Code di aprire/chiudere Perplexity e di invocare ricerche autonomamente.

### 3.7 Browser Esterno — Chrome

**Non è un pannello tmux.** Chrome viene aperto come applicazione esterna e posizionato via AppleScript.

**Flusso:**
1. Claude Code (o l'utente) richiede l'apertura di un URL
2. L'MCP tool `open_browser` (o uno script) controlla se è la prima apertura nella sessione
3. Se sì → dialog AppleScript: "50/50 o Tutto schermo?"
4. Applica il layout scelto con AppleScript
5. Apre Chrome all'URL richiesto

**AppleScript per 50/50:**
```applescript
tell application "System Events"
    set screenSize to get size of scroll area 1 of process "Finder"
    set screenWidth to item 1 of screenSize
    set screenHeight to item 2 of screenSize
    set halfWidth to screenWidth / 2
end tell
tell application "Ghostty"
    set bounds of front window to {0, 0, halfWidth, screenHeight}
end tell
tell application "Google Chrome"
    activate
    set bounds of front window to {halfWidth, 0, screenWidth, screenHeight}
end tell
```

**AppleScript per fullscreen Chrome:**
```applescript
tell application "Google Chrome"
    activate
end tell
tell application "System Events"
    keystroke "f" using {control down, command down}
end tell
```

**Perché Chrome:** buona integrazione con Chrome DevTools Protocol, Claude Code può interagire con esso, è il browser più diffuso per sviluppo web.

---

## 4. Barre di Stato

### 4.1 Status Bar Superiore (tmux status-top)

Contenuto:
```
[Prg1] [Prg2] [Prg3]          CPU: 23% │ RAM: 67% │ 19/02 07:37
```

| Elemento | Implementazione |
|---|---|
| Tab progetto | Nativo tmux (window list) |
| CPU % | Script shell: `top -l 1 | grep "CPU usage"` (macOS) |
| RAM % | Script shell: `vm_stat` + calcolo (macOS) |
| Data e ora | `strftime` nativo tmux |

**Refresh:** tmux aggiorna la status bar ogni `status-interval` secondi (configurabile, default 15).

### 4.2 Git Bar Inferiore (tmux status-bottom)

Contenuto informativo:
```
🔀 main │ ✓ clean │ abc1234 "fix auth" │ +2 -1
```

**Tool:** gitmux (`brew install gitmux`)

gitmux è un widget tmux specifico per informazioni git. Si configura con un file `.gitmux.conf` che definisce il formato. tmux lo invoca automaticamente nella status bar.

### 4.3 Git Bar — Azioni Interattive via Keybinding

La barra mostra le informazioni; le azioni si eseguono con keybinding dedicati.

**Key table tmux "git-mode":**

| Sequenza | Azione | Implementazione |
|---|---|---|
| `prefix + g b` | Switch branch | `display-popup -E "git branch \| fzf \| xargs git checkout"` |
| `prefix + g c` | Commit | `display-popup -E 'read -p "Commit message: " msg && git add -A && git commit -m "$msg"'` |
| `prefix + g p` | Push | `send-keys -t {terminale}` → `git push` + Enter |
| `prefix + g s` | Status | `display-popup -E "git status"` |
| `prefix + g l` | Log grafico | `display-popup -E "git log --oneline --graph -20"` |
| `prefix + g g` | Lazygit (completo) | `display-popup -w 80% -h 80% -E "lazygit"` |

**Meccanismo:** tmux key table. `prefix + g` attiva la tabella "git-table", il tasto successivo esegue l'azione.

```tmux
# In tmux.conf
bind-key g switch-client -T git-table
bind-key -T git-table b display-popup -E "git branch | fzf | xargs git checkout"
bind-key -T git-table c display-popup -E 'read -p "Commit msg: " msg && git add -A && git commit -m "$msg"'
bind-key -T git-table p send-keys -t {bottom-right} "git push" Enter
bind-key -T git-table s display-popup -E "git status"
bind-key -T git-table l display-popup -E "git log --oneline --graph -20"
bind-key -T git-table g display-popup -w 80% -h 80% -E "lazygit"
```

**Requisiti:** tmux ≥ 3.3 (per display-popup), fzf, lazygit (opzionale).

---

## 5. MCP Server — tmux-mcp

### 5.1 Panoramica

Il cuore architetturale del progetto. Un MCP server che espone a Claude Code la capacità di interagire con tutti i pannelli tmux.

**Linguaggio:** TypeScript
**Trasporto:** stdio (standard per MCP server locali con Claude Code)
**SDK:** `@modelcontextprotocol/sdk`
**Runtime:** Node.js ≥ 18

### 5.2 Tool Esposti

#### Tool di Lettura

| Tool | Parametri | Descrizione |
|---|---|---|
| `tmux_capture_pane` | `target_pane`, `lines`, `start`, `end` | Cattura il contenuto visibile o buffer di un pannello |
| `tmux_list_sessions` | — | Elenco sessioni con metadata |
| `tmux_list_windows` | `session` | Elenco finestre (tab/progetti) di una sessione |
| `tmux_list_panes` | `window` | Elenco pannelli con dimensioni, PID, processo attivo |
| `tmux_pane_info` | `target_pane` | Info dettagliata su un singolo pannello |

#### Tool di Azione

| Tool | Parametri | Descrizione |
|---|---|---|
| `tmux_send_keys` | `target_pane`, `keys`, `enter` | Invia sequenze di tasti a un pannello |
| `tmux_create_pane` | `target_window`, `direction`, `size`, `command` | Crea nuovo pannello con split |
| `tmux_close_pane` | `target_pane` | Chiude un pannello |
| `tmux_resize_pane` | `target_pane`, `direction`, `amount` | Ridimensiona un pannello |
| `tmux_select_layout` | `layout_name` | Applica layout predefinito |

#### Tool di Monitoraggio

| Tool | Parametri | Descrizione |
|---|---|---|
| `tmux_watch_pane` | `target_pane`, `interval`, `pattern` | Cattura ripetuta con diff, opzionale match pattern |

#### Tool di Integrazione

| Tool | Parametri | Descrizione |
|---|---|---|
| `open_browser` | `url` | Apre Chrome con layout AppleScript (gestisce dialog prima apertura) |
| `toggle_perplexity` | `query` (opzionale) | Apre/chiude pannello Perplexity, opzionalmente con query |
| `git_action` | `action`, `params` | Esegue azioni git (branch, commit, push) |

### 5.3 Architettura del Server

```
tmux-mcp/
├── src/
│   ├── index.ts              # Entry point, setup MCP server
│   ├── server.ts             # Definizione server e registrazione tool
│   ├── tools/
│   │   ├── capture.ts        # tmux_capture_pane
│   │   ├── list.ts           # tmux_list_sessions/windows/panes
│   │   ├── send.ts           # tmux_send_keys
│   │   ├── manage.ts         # create/close/resize pane
│   │   ├── watch.ts          # tmux_watch_pane
│   │   ├── browser.ts        # open_browser (AppleScript integration)
│   │   ├── perplexity.ts     # toggle_perplexity
│   │   └── git.ts            # git_action
│   ├── tmux/
│   │   ├── client.ts         # Wrapper per comandi tmux CLI
│   │   ├── parser.ts         # Parsing output tmux
│   │   └── types.ts          # Tipi TypeScript per entità tmux
│   ├── utils/
│   │   ├── ansi.ts           # Stripping codici ANSI dall'output catturato
│   │   ├── applescript.ts    # Esecuzione AppleScript
│   │   └── errors.ts         # Gestione errori strutturata
│   └── config.ts             # Configurazione (nomi pannelli, layout, ecc.)
├── package.json
├── tsconfig.json
└── README.md
```

### 5.4 Gestione Errori

Ogni tool restituisce errori strutturati:
```typescript
{
  error: {
    code: "PANE_NOT_FOUND" | "SESSION_NOT_FOUND" | "COMMAND_TIMEOUT" | "TMUX_ERROR",
    message: string,
    details?: any
  }
}
```

**Scenari da gestire:**
- Pannello non trovato (ID invalido o pannello chiuso)
- Sessione non esistente
- Timeout su send-keys (comando non produce output atteso)
- Permessi tmux insufficienti
- tmux non in esecuzione

### 5.5 Sicurezza

- **Logging completo:** ogni invocazione di `tmux_send_keys` viene loggata con timestamp, target, e contenuto
- **Conferma per azioni distruttive:** `tmux_close_pane` su pannelli con processi attivi segnala il rischio nel response
- **Whitelist opzionale:** possibilità di limitare i comandi inviabili via send-keys (configurabile)
- **Sandboxing:** il server non ha permessi oltre quelli necessari per interagire con tmux

### 5.6 Gestione Race Condition su send-keys

**Problema:** se Claude Code invia comandi rapidi a un pannello, possono sovrapporsi se il processo non ha finito di processare il precedente.

**Soluzione:** meccanismo "wait for prompt" nel tool `tmux_send_keys`:
1. Invia il comando
2. Polling con `capture-pane` a intervalli brevi (100-200ms)
3. Cerca un pattern configurabile (prompt shell `$`/`❯`, prompt Python `>>>`, ecc.)
4. Restituisce il risultato solo quando il prompt riappare (o dopo timeout)

### 5.7 Registrazione in Claude Code

In `~/.claude/settings.json`:
```json
{
  "mcpServers": {
    "tmux-mcp": {
      "command": "node",
      "args": ["/path/to/tmux-mcp/dist/index.js"],
      "transportType": "stdio"
    }
  }
}
```

---

## 6. Keybinding Completi

### 6.1 Navigazione Pannelli

| Keybinding | Azione |
|---|---|
| `prefix + h/j/k/l` | Navigazione vim-style tra pannelli |
| `prefix + 1-5` | Salto diretto al pannello (1=Yazi, 2=CC, 3=Usage, 4=Log, 5=Term) |
| `prefix + z` | Zoom/unzoom pannello corrente (fullscreen toggle) |

### 6.2 Azioni Git

| Keybinding | Azione |
|---|---|
| `prefix + g b` | Switch branch (fzf popup) |
| `prefix + g c` | Commit (popup con input messaggio) |
| `prefix + g p` | Push (nel terminale) |
| `prefix + g s` | Status (popup) |
| `prefix + g l` | Log grafico (popup) |
| `prefix + g g` | Lazygit (popup grande) |

### 6.3 Toggle Pannelli

| Keybinding | Azione |
|---|---|
| `prefix + p` | Toggle Perplexity (split/close su Claude Code) |
| `prefix + o` | Apri browser Chrome (con dialog layout) |

### 6.4 Gestione Progetti/Tab

| Keybinding | Azione |
|---|---|
| `prefix + c` | Nuovo progetto (nuovo tab con setup completo) |
| `prefix + n/p` | Prossimo/precedente progetto |
| `prefix + ,` | Rinomina progetto |
| `prefix + w` | Lista progetti (window chooser) |

---

## 7. Script di Bootstrap

### 7.1 Concetto

Un singolo script `tmux-ide` (o `tmux-ide.sh`) che:
1. Crea la sessione tmux con il layout completo
2. Lancia tutti i processi nei pannelli
3. Configura status bar, keybinding, e opzioni
4. Accetta come argomento la directory del progetto

**Uso:**
```bash
tmux-ide ~/projects/my-app
# oppure senza argomento → usa la directory corrente
```

### 7.2 Cosa Fa lo Script

1. **Setup sessione tmux** con nome basato sulla directory
2. **Creazione pannelli** nella disposizione definita (split orizzontali e verticali)
3. **Lancio processi:**
   - Pannello 1: `yazi` nella directory del progetto
   - Pannello 2: `claude` (Claude Code)
   - Pannello 3: `claude-monitor --plan max5 --theme dark`
   - Pannello 4: `tail -f` sul log del progetto (o shell vuota)
   - Pannello 5: `zsh` (terminale interattivo)
4. **Configurazione status bar** superiore (CPU, RAM, data) e inferiore (gitmux)
5. **Registrazione keybinding** (git, toggle, navigazione)
6. **Attach alla sessione** o focus se già esiste

### 7.3 Aggiunta Progetto

Per aggiungere un nuovo progetto a una sessione esistente:
```bash
tmux-ide --add ~/projects/another-app
```
Questo crea un nuovo tab (window) nella sessione esistente con lo stesso layout.

---

## 8. Dipendenze Complete

### 8.1 Requisiti di Sistema

| Dipendenza | Installazione | Versione Min | Ruolo |
|---|---|---|---|
| macOS | — | Ventura+ | Sistema operativo |
| Ghostty | Download sito ufficiale | Ultima stabile | Emulatore terminale |
| tmux | `brew install tmux` | 3.3+ | Multiplexer (serve display-popup) |
| Node.js | `brew install node` | 18+ | Runtime MCP server e Claude Code |
| Python | Sistema o `brew install python` | 3.9+ | claude-monitor, perplexity-cli |
| uv | `curl -LsSf https://astral.sh/uv/install.sh \| sh` | Ultima | Package manager Python |

### 8.2 Tool CLI

| Tool | Installazione | Ruolo |
|---|---|---|
| Claude Code | `npm install -g @anthropic-ai/claude-code` | Agente AI |
| Yazi | `brew install yazi` | File browser |
| Neovim + LazyVim | `brew install neovim` + config LazyVim | Editor |
| claude-monitor | `uv tool install claude-monitor` | Usage monitor |
| perplexity-cli | Download da GitHub (vedi §3.6) | Ricerca web |
| gitmux | `brew install gitmux` | Git info status bar |
| fzf | `brew install fzf` | Selezione fuzzy (branch, ecc.) |
| lazygit | `brew install lazygit` | TUI git completa |
| ffmpegthumbnailer | `brew install ffmpegthumbnailer` | Anteprime video in Yazi |
| ImageMagick | `brew install imagemagick` | Conversione immagini (opzionale) |

### 8.3 Librerie Node.js (MCP Server)

| Pacchetto | Ruolo |
|---|---|
| `@modelcontextprotocol/sdk` | SDK MCP ufficiale |
| `typescript` | Linguaggio |
| `tsx` | Esecuzione diretta TypeScript (dev) |
| `zod` | Validazione parametri tool |

### 8.4 Repository di Riferimento

| Repo | URL | Uso |
|---|---|---|
| Claude Code Usage Monitor | https://github.com/Maciek-roboblog/Claude-Code-Usage-Monitor | Pannello usage |
| Perplexity CLI | https://github.com/dawid-szewc/perplexity-cli | Pannello ricerca |
| MCP SDK TypeScript | https://github.com/modelcontextprotocol/typescript-sdk | Base MCP server |
| Yazi | https://github.com/sxyazi/yazi | File browser |
| gitmux | https://github.com/arl/gitmux | Git status bar |
| lazygit | https://github.com/jesseduffield/lazygit | TUI git |

---

## 9. Rischi e Criticità Architetturali

### 9.1 Race Condition su send-keys
**Rischio:** comandi sovrapposti se Claude Code invia input rapidi a un pannello.
**Mitigazione:** meccanismo "wait for prompt" con polling capture-pane (§5.6).

### 9.2 Rumore ANSI su capture-pane
**Rischio:** `tmux capture-pane` cattura codici ANSI che inquinano il contenuto per Claude Code.
**Mitigazione:** stripping ANSI con regex o libreria dedicata nel server MCP prima di restituire il contenuto.

### 9.3 Context Window Overflow
**Rischio:** catture frequenti di pannelli con molto testo riempiono il context window di Claude Code.
**Mitigazione:** limitare il default a ultime 50 righe per cattura. Claude Code può richiedere di più esplicitamente.

### 9.4 Stabilità Layout su Resize
**Rischio:** ridimensionando Ghostty, tmux ricalcola i pannelli e può comprimere quelli piccoli.
**Mitigazione:** `set-option -g pane-minimum-size` e hook tmux `after-resize-window` per ribilanciare.

### 9.5 Multi-Istanza Claude Code e Consumo
**Rischio:** ogni tab con la propria istanza Claude Code consuma dall'abbonamento. Molti tab = rate limit più rapido.
**Mitigazione:** consapevolezza dell'utente. Il pannello usage monitor aiuta. Valutare in futuro un'istanza singola che switcha contesto.

### 9.6 Ghostty e Mouse in tmux
**Rischio:** click sui bordi dei pannelli può finire nel pannello sbagliato.
**Mitigazione:** bordi visibili con `pane-border-style`, padding adeguato.

### 9.7 `/usage` e claude-monitor
**Rischio:** claude-monitor legge i file di sessione di Claude Code. Se Anthropic cambia il formato dei file, il monitor si rompe.
**Mitigazione:** il repo è attivamente mantenuto (6.5k stelle, v3.1.0). Seguire gli aggiornamenti.

### 9.8 Perplexity API Key
**Rischio:** il piano API Perplexity è separato dall'abbonamento consumer. Richiede registrazione e pagamento a consumo.
**Mitigazione:** verificare di avere accesso all'API prima di implementare il pannello. In alternativa, Claude Code ha già web search integrato.

---

## 10. Piano di Implementazione

### Fase 1 — MVP Core (Settimane 1-2)

**Obiettivo:** layout tmux funzionante con pannelli base.

**Deliverable:**
- [ ] Script `tmux-ide` che crea il layout completo
- [ ] Configurazione tmux (status bar, keybinding navigazione)
- [ ] Pannelli attivi: Yazi, Claude Code, terminale, log (tail -f)
- [ ] Status bar superiore: tab, CPU, RAM, data/ora
- [ ] Status bar inferiore: gitmux
- [ ] Ghostty fullscreen all'avvio

### Fase 2 — MCP Server Base (Settimane 2-3)

**Obiettivo:** Claude Code può leggere e scrivere sui pannelli.

**Deliverable:**
- [ ] Progetto TypeScript tmux-mcp inizializzato
- [ ] Tool implementati: `capture_pane`, `send_keys`, `list_panes`
- [ ] Registrazione in Claude Code settings
- [ ] Test: Claude Code legge output dal log e terminale
- [ ] Gestione errori base

### Fase 3 — MCP Server Completo + Git (Settimane 3-4)

**Obiettivo:** tutti i tool MCP, azioni git interattive.

**Deliverable:**
- [ ] Tool aggiuntivi: create/close/resize pane, list sessions/windows
- [ ] `watch_pane` con diff
- [ ] Stripping ANSI completo
- [ ] Wait-for-prompt su send_keys
- [ ] Keybinding git completi (prefix+g table)
- [ ] Popup fzf per branch switch
- [ ] Lazygit nel popup

### Fase 4 — Integrazioni Esterne (Settimane 4-5)

**Obiettivo:** usage monitor, Perplexity, browser.

**Deliverable:**
- [ ] Pannello claude-monitor configurato e funzionante
- [ ] Toggle Perplexity (prefix+p)
- [ ] Tool MCP `open_browser` con dialog AppleScript
- [ ] Gestione layout 50/50 e fullscreen per Chrome
- [ ] Tool MCP `toggle_perplexity`

### Fase 5 — Anteprime e Polish (Settimane 5-6)

**Obiettivo:** esperienza completa e rifinita.

**Deliverable:**
- [ ] Custom previewer Yazi con qlmanage (Quick Look)
- [ ] Apertura file in LazyVim da Yazi
- [ ] Multi-progetto: `tmux-ide --add` per nuovi tab
- [ ] Profili layout per tipi di progetto (web, script, ecc.)
- [ ] Documentazione utente
- [ ] Indicatore usage sintetico nella status bar superiore (opzionale)

---

## 11. Decisioni di Design Consolidate

| Decisione | Scelta | Alternativa Scartata | Motivazione |
|---|---|---|---|
| Terminal emulator | Ghostty | iTerm2, Alacritty | Kitty graphics protocol, performance, modernità |
| File browser | Yazi | ranger, lf, nnn | Rust, veloce, anteprime native, mouse support |
| Usage monitor | claude-monitor (PyPI) | Script custom con /usage | Tool maturo, ML predictions, nessun hack |
| Perplexity | perplexity-cli + toggle | Pannello fisso | Risparmio spazio, uso intermittente |
| Browser | Chrome + AppleScript | Tiling WM, browsh | Zero intrusioni sistema, Chrome DevTools |
| Git actions | Keybinding + popup tmux | Barra cliccabile | tmux status non è interattiva |
| Git TUI | lazygit (opzionale) | tig, gitui | Più completo, più diffuso |
| MCP linguaggio | TypeScript | Python (FastMCP) | Coerente con ecosistema Claude Code/MCP SDK |
| MCP trasporto | stdio | SSE, HTTP | Standard per MCP server locali |
| Tiling WM | ❌ Escluso | Aerospace, yabai | Non vogliamo modificare il workflow desktop |
| Multi-progetto | Tab tmux, istanza CC per tab | Singola istanza | Isolamento contesto per progetto |
| Anteprime file | qlmanage (Quick Look macOS) | sixel, chafa custom | Nativo, supporta tutti i formati Office |

---

## 12. Glossario

| Termine | Significato |
|---|---|
| **Pannello** | Pane tmux — suddivisione di una finestra |
| **Tab / Finestra** | Window tmux — corrisponde a un progetto |
| **Sessione** | Session tmux — il container principale |
| **MCP** | Model Context Protocol — standard Anthropic per tool AI |
| **Claude Code** | CLI AI di Anthropic per sviluppo assistito |
| **Ghostty** | Emulatore terminale moderno con supporto Kitty graphics |
| **Yazi** | File manager TUI in Rust |
| **gitmux** | Widget tmux per informazioni git |
| **display-popup** | Funzionalità tmux ≥ 3.3 per overlay popup |
| **key table** | Meccanismo tmux per keybinding multi-tasto (come vim leader) |
| **capture-pane** | Comando tmux per catturare il contenuto di un pannello |
| **send-keys** | Comando tmux per inviare input a un pannello |
| **stdio** | Trasporto standard input/output per MCP server locali |
| **BMAD** | Metodologia per design architetturale e sviluppo |

---

*Questo documento cattura tutte le decisioni prese durante la fase di analisi e design. È pronto per essere utilizzato come input per la progettazione architetturale con BMAD e successivo sviluppo.*
