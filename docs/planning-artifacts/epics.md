---
stepsCompleted: ['step-01-validate-prerequisites', 'step-02-design-epics', 'step-03-create-stories', 'step-04-final-validation']
status: 'complete'
completedAt: '2026-02-19'
inputDocuments:
  - 'docs/planning-artifacts/prd.md'
  - 'docs/planning-artifacts/prd-decisions-log.md'
  - 'docs/planning-artifacts/architecture.md'
  - 'docs/tmux-mcp-ide-spec.md'
---

# BigIDE - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for BigIDE, decomposing the requirements from the PRD, Architecture, and the original tmux-mcp IDE spec into implementable stories.

## Requirements Inventory

### Functional Requirements

**Avvio e Gestione Sessione (6 FR)**

- FR1: L'utente può avviare BigIDE con un singolo comando (`bigide`) che lancia Ghostty in fullscreen e crea la sessione tmux con il layout completo
- FR2: BigIDE può rilevare una sessione tmux esistente e riattaccarsi ad essa invece di crearne una nuova
- FR3: L'utente può aprire un nuovo progetto in un nuovo tab tmux dall'interno dell'IDE tramite keybinding dedicato, specificando il percorso
- FR4: BigIDE può forzare Ghostty in modalità fullscreen all'avvio e mantenerla durante l'uso
- FR5: BigIDE può rilevare una cartella vuota e proporre l'inizializzazione automatica del progetto (BMAD, autoprovision, repo GitHub)
- FR5b: BigIDE può mostrare una splash screen con progress bar durante l'avvio e l'installazione, comunicando all'utente cosa sta facendo in ogni momento

**Layout e Navigazione Pannelli (5 FR)**

- FR6: BigIDE può creare e mantenere un layout a pannelli con proporzioni definite e architettura estensibile per supportare nuovi pannelli e disposizioni future
- FR7: L'utente può navigare tra i pannelli tramite keybinding direzionali (prefix + frecce direzionali)
- FR8: L'utente può saltare direttamente a un pannello specifico tramite keybinding numerici (prefix + 1-5)
- FR9: L'utente può espandere un pannello in fullscreen temporaneo (zoom) e tornare al layout con lo stesso keybinding
- FR10: BigIDE può ribilanciare automaticamente le proporzioni dei pannelli dopo eventi di resize

**Esplorazione File (5 FR)**

- FR11: L'utente può navigare il file system del progetto tramite file browser (Yazi) usando tastiera e mouse
- FR12: L'utente può visualizzare anteprime di immagini direttamente nel file browser
- FR13: L'utente può visualizzare anteprime di file Office/PDF tramite Quick Look macOS nel file browser
- FR14: L'utente può aprire un file nell'editor integrato (LazyVim overlay) dal file browser
- FR15: L'utente può salvare e chiudere l'editor overlay tornando al file browser con il file aggiornato

**Agente AI — Claude Code + MCP (7 FR)**

- FR16: Claude Code può catturare il contenuto visibile di qualsiasi pannello tmux tramite MCP
- FR17: Claude Code può inviare comandi e sequenze di tasti a qualsiasi pannello tmux tramite MCP
- FR18: Claude Code può elencare tutti i pannelli della sessione con informazioni su dimensioni, processo attivo e stato
- FR19: Il server MCP può rimuovere i codici ANSI dall'output catturato prima di restituirlo a Claude Code
- FR20: Il server MCP può attendere la ricomparsa del prompt shell dopo l'invio di un comando prima di restituire il risultato (wait-for-prompt)
- FR21: Claude Code può creare, chiudere e ridimensionare pannelli tmux tramite MCP
- FR22: Claude Code può monitorare un pannello con catture periodiche e rilevamento differenze (watch)

**Integrazione Browser (3 FR)**

- FR23: Claude Code può aprire un URL in Chrome tramite MCP, con posizionamento automatico della finestra
- FR24: BigIDE può presentare una scelta di layout browser alla prima apertura della sessione (50/50 o fullscreen separato)
- FR25: BigIDE può posizionare Chrome e Ghostty secondo il layout scelto tramite AppleScript

**Git e Version Control (7 FR)**

- FR26: La barra di stato inferiore può mostrare informazioni git in tempo reale (branch, stato, ultimo commit, diff count)
- FR27: L'utente può cambiare branch tramite keybinding con selezione fuzzy in popup
- FR28: L'utente può creare un commit tramite keybinding con popup per il messaggio
- FR29: L'utente può eseguire push tramite keybinding dedicato
- FR30: L'utente può visualizzare status e log git tramite keybinding con popup
- FR31: L'utente può aprire una TUI git completa (lazygit) in popup a schermo quasi pieno
- FR32: L'utente può interagire con le funzionalità git anche tramite mouse sulla barra git e sui popup

**Monitoraggio e Status (3 FR)**

- FR33: La barra di stato superiore può mostrare la lista dei tab/progetti, uso CPU, uso RAM e data/ora
- FR34: Il pannello usage monitor può mostrare il consumo token di Claude Code in tempo reale con progress bar e predizioni
- FR35: BigIDE può aggiornare le informazioni delle barre di stato a intervalli configurabili

**Configurazione e Personalizzazione (3 FR)**

- FR36: BigIDE può mantenere tutte le configurazioni in una cartella dedicata (`~/.bigide/`) senza modificare configurazioni globali dell'utente
- FR37: L'utente può personalizzare il tema visivo dell'IDE tramite file di configurazione
- FR38: BigIDE può applicare configurazioni dedicate a tmux, Ghostty, Yazi e Neovim isolate da quelle personali

**Installazione e Manutenzione (4 FR)**

- FR39: BigIDE può verificare e installare automaticamente tutte le dipendenze necessarie al primo avvio (brew, Ghostty, tmux, Node.js, Yazi, gitmux, Claude Code, ecc.)
- FR40: L'installer può essere rieseguito in modo idempotente senza danni alle installazioni esistenti
- FR41: L'utente può riparare il server MCP senza perdere la sessione di lavoro (`bigide --repair`)
- FR42: L'utente può aggiornare BigIDE e le sue dipendenze tramite un singolo comando

**Memoria e Autoapprendimento (4 FR)**

- FR43: Claude Code può salvare procedure risolutive e pattern nella memoria persistente del progetto
- FR44: Claude Code può consultare la memoria persistente prima di diagnosticare un problema già incontrato
- FR45: Claude Code può generare script di recovery riutilizzabili e salvarli in una cartella dedicata
- FR46: Il sistema di memoria può distinguere tra conoscenza specifica del progetto e conoscenza generale condivisa tra progetti

**Input Vocale (1 FR)**

- FR47: L'utente può utilizzare la dittatura vocale locale (zero token) come canale di input alternativo alla tastiera — ultima priorità assoluta di implementazione

**Scopribilità e Onboarding (1 FR)**

- FR48: BigIDE può mostrare un banner contestuale con i keybinding disponibili dopo il prefix (which-key), attivato automaticamente dopo 500ms di attesa post-prefix, e un help completo tramite `prefix + ?`

### NonFunctional Requirements

**Performance (5 NFR)**

- NFR1: Le operazioni MCP (capture_pane, send_keys) devono completarsi in < 500ms percepiti dall'utente
- NFR2: Il meccanismo wait-for-prompt deve rilevare il prompt entro 5 secondi o restituire timeout
- NFR3: La navigazione tra pannelli (keybinding) deve essere istantanea (< 100ms)
- NFR4: L'avvio dell'IDE deve mostrare una splash screen con progress bar che comunica lo stato di ogni fase. Il tempo di avvio non è critico purché l'utente abbia feedback visivo continuo
- NFR5: Le status bar devono aggiornarsi senza impatto percepibile sulle prestazioni degli altri pannelli

**Accessibilita (5 NFR)**

- NFR6: >=90% delle operazioni dell'IDE devono essere eseguibili esclusivamente da tastiera
- NFR7: Tutti i keybinding devono essere eseguibili con una mano (o sequenziali, non chord complessi simultanei) per minimizzare lo sforzo motorio
- NFR8: I testi nelle status bar e nei pannelli devono avere contrasto sufficiente per leggibilita in tutte le condizioni di luce
- NFR9: Il mouse deve essere supportato come canale di input supplementare dove appropriato (git bar, file browser, selezione pannello)
- NFR10: L'interfaccia non deve richiedere movimenti precisi del mouse — target di click ampi, nessun drag & drop obbligatorio

**Affidabilita (5 NFR)**

- NFR11: Una sessione di lavoro di 1+ ore non deve presentare crash del layout o del server MCP
- NFR12: Il fallimento di un singolo componente (MCP, Yazi, log) non deve bloccare gli altri pannelli
- NFR13: Il layout deve mantenere le proporzioni corrette per l'intera sessione con Ghostty in fullscreen
- NFR14: L'installer deve essere idempotente — riesecuzioni multiple non devono causare danni o inconsistenze
- NFR15: La memoria persistente dell'agente deve sopravvivere a crash della sessione senza perdita di dati

**Integrazione (4 NFR)**

- NFR16: Il server MCP deve funzionare con Claude Code via trasporto stdio senza configurazione manuale dopo l'installazione
- NFR17: BigIDE deve funzionare con tmux >= 3.3 e Ghostty versione stabile corrente
- NFR18: L'integrazione Chrome via AppleScript deve funzionare su macOS Ventura e successivi
- NFR19: L'aggiornamento di una dipendenza esterna (tmux, Yazi, Claude Code) non deve rompere BigIDE — degradazione graceful con messaggio chiaro

### Additional Requirements

**Da Architecture — Decisioni Tecnologiche che impattano l'implementazione:**

- Starter template MCP: scaffoldato con `npx @modelcontextprotocol/create-server tmux-mcp` (SDK v1.26.0)
- Shell bootstrap in bash puro con `set -euo pipefail`, zero dipendenze esterne al primo run
- Formato configurazione: JSON (`~/.bigide/config.json`) — nativo in TypeScript, leggibile con `jq` in bash
- Layout tmux dichiarativo da file JSON (`~/.bigide/layouts/default.json`) — lo script bash interpreta con `jq`
- MCP server TypeScript con architettura file-per-tool (`tools/capture.ts`, `tools/send.ts`, ecc.)
- Error codes strutturati nel MCP: `PANE_NOT_FOUND`, `SESSION_NOT_FOUND`, `COMMAND_TIMEOUT`, `TMUX_ERROR`, `APPLESCRIPT_ERROR`, `INVALID_PARAMS`
- Wait-for-prompt implementato con polling capture-pane (100-200ms intervallo, pattern prompt configurabile)
- ANSI stripping con regex in `utils/ansi.ts`
- Splash screen in ANSI puro: Unicode progress bar, colori ANSI, `\r` per sovrascrittura
- Logging su file persistenti (`~/.bigide/logs/mcp.log`, `~/.bigide/logs/bigide.log`) + stderr per errori critici
- Distribuzione MVP: clone repo + `setup.sh`; rilascio pubblico: curl one-liner; self-update: `bigide --update`
- Ghostty configurato via flag CLI inline — nessun file config separato nel MVP
- jq come dipendenza per parsing JSON in bash
- Wrapper pattern obbligatorio: `TmuxClient` per TypeScript, funzioni `lib/` per bash — mai comandi tmux diretti nei tool
- Naming conventions: bash=`snake_case`, TypeScript=`camelCase`, JSON config=`camelCase`
- Fail-open error handling cross-linguaggio: nessun componente deve crashare per errori gestibili
- Config JSON schema con defaults e versioning (`"version": 1`)
- Memoria persistente: claude-mem as-is (senza fork), separazione progetto/generale tramite filtri per project path
- Separazione netta repo (`config/`) → runtime (`~/.bigide/`): l'installer copia, l'utente modifica solo runtime

**Da Architecture — Struttura Repository:**

- `bin/bigide` — entry point bash in PATH
- `src/shell/lib/` — funzioni bash modulari (deps, layout, splash, session, repair, update, status, config-reader)
- `src/shell/applescript/` — script AppleScript (chrome-split, chrome-fullscreen, ghostty-fullscreen)
- `src/mcp/` — progetto Node.js indipendente con proprio package.json
- `config/` — file config sorgente (layouts, tmux.conf, gitmux.conf, yazi/)
- `tests/mcp/` — test MCP server (specchia tools/)
- `tests/shell/` — test bash con bats

**Da Architecture — Sequenza di Implementazione Raccomandata:**

1. Layout JSON dichiarativo (prerequisito per tutto il resto)
2. Script bash bootstrap con splash ANSI (entry point)
3. MCP server TypeScript (file-per-tool, 4 tool MVP)
4. Config JSON + logging
5. Installer idempotente con verifica dipendenze

**Da Spec Originale (tmux-mcp-ide-spec.md) — Requisiti aggiuntivi:**

- Pannello Perplexity toggle con `prefix+p` (divide Claude Code al 50% quando attivo)
- Dialog AppleScript per scelta layout browser (50/50 o fullscreen) alla prima apertura nella sessione
- Key table tmux multi-livello per git (`prefix+g` attiva `git-table`, secondo tasto esegue azione)
- Custom previewer Yazi con `qlmanage` per Quick Look macOS (ql-preview.sh)
- Multi-progetto: ogni tab tmux = progetto separato con istanza Claude Code indipendente
- Logging completo di ogni invocazione `send_keys` (timestamp, target, contenuto)
- Conferma/segnalazione rischio per azioni distruttive (`close_pane` su processi attivi)
- Context window overflow mitigato: default 50 righe per cattura, Claude Code richiede di piu esplicitamente
- Proporzioni layout MVP: Yazi 25%/70%, Claude Code 75%/70%, Usage 15%/30%, Log 35%/30%, Terminale 50%/30%

**Da PRD Decisions Log — Decisioni chiave da rispettare:**

- MCP nel MVP (non in Phase 2): solo 4 tool base (`capture_pane`, `send_keys`, `list_panes`, `open_browser`)
- Tool avanzati MCP (`watch_pane`, `create_pane`, `close_pane`, `resize_pane`) rimandati a Phase 2
- Setup script guidato nel MVP; installer completo idempotente in Phase 2
- Dittatura vocale: ultima priorita assoluta di implementazione (ultima feature di Phase 2)
- Keybinding navigazione: `prefix + frecce direzionali` (non vim-style h/j/k/l)
- Layout estensibile per supportare futuri pannelli e disposizioni
- Mouse supportato nei popup git interattivi e file browser (non sulla barra git, che resta informativa)

### FR Coverage Map

| FR | Epic | Descrizione |
|----|------|-------------|
| FR1 | Epic 1 | Avvio con singolo comando `bigide` |
| FR2 | Epic 1 | Riattach sessione tmux esistente |
| FR4 | Epic 1 | Ghostty fullscreen forzato |
| FR5b | Epic 1 | Splash screen con progress bar |
| FR6 | Epic 1 | Layout pannelli con proporzioni definite |
| FR7 | Epic 1 | Navigazione keybinding direzionali |
| FR8 | Epic 1 | Salto diretto pannello (prefix+1-5) |
| FR9 | Epic 1 | Zoom/unzoom pannello |
| FR10 | Epic 1 | Ribilanciamento automatico resize |
| FR26 | Epic 1 | Git bar inferiore (gitmux) |
| FR33 | Epic 1 | Status bar superiore (tab, CPU, RAM, ora) |
| FR35 | Epic 1 | Aggiornamento status bar a intervalli configurabili |
| FR36 | Epic 1 | Configurazioni in `~/.bigide/` isolate |
| FR37 | Epic 1 | Personalizzazione tema visivo |
| FR38 | Epic 1 | Config dedicate per tmux, Ghostty, Yazi, Neovim |
| FR11 | Epic 2 | Navigazione file con Yazi (tastiera + mouse) |
| FR12 | Epic 2 | Anteprime immagini nel file browser |
| FR13 | Epic 2 | Anteprime Office/PDF via Quick Look |
| FR14 | Epic 2 | Apertura file in LazyVim overlay |
| FR15 | Epic 2 | Salva e chiudi editor overlay |
| FR16 | Epic 3 | MCP capture_pane |
| FR17 | Epic 3 | MCP send_keys |
| FR18 | Epic 3 | MCP list_panes |
| FR19 | Epic 3 | ANSI stripping output |
| FR20 | Epic 3 | Wait-for-prompt |
| FR23 | Epic 4 | Apertura URL in Chrome via MCP |
| FR24 | Epic 4 | Scelta layout browser (50/50 o fullscreen) |
| FR25 | Epic 4 | Posizionamento Chrome/Ghostty via AppleScript |
| FR27 | Epic 5 | Branch switch con fuzzy popup |
| FR28 | Epic 5 | Commit con popup messaggio |
| FR29 | Epic 5 | Push tramite keybinding |
| FR30 | Epic 5 | Status e log git in popup |
| FR31 | Epic 5 | Lazygit in popup grande |
| FR32 | Epic 5 | Interazione mouse su popup git |
| FR39 | Epic 6 | Installazione automatica dipendenze |
| FR40 | Epic 6 | Installer idempotente |
| FR41 | Epic 6 | Repair MCP senza perdita sessione |
| FR42 | Epic 6 | Aggiornamento con singolo comando |
| FR3 | Epic 7 | Nuovo progetto in nuovo tab tmux |
| FR21 | Epic 7 | MCP create/close/resize pane |
| FR22 | Epic 7 | MCP watch_pane con diff |
| FR34 | Epic 7 | Usage monitor token in tempo reale |
| FR5 | Epic 8 | Rilevamento cartella vuota e auto-provisioning |
| FR43 | Epic 9 | Salvataggio procedure in memoria persistente |
| FR44 | Epic 9 | Consultazione memoria per diagnostica |
| FR45 | Epic 9 | Generazione script recovery riutilizzabili |
| FR46 | Epic 9 | Separazione memoria progetto/generale |
| FR47 | Epic 10 | Dittatura vocale locale (Whisper.cpp) |
| FR48 | Epic 1 | Which-key banner per scopribilità keybinding |

## Epic List

### Epic 1: L'IDE Prende Vita — Bootstrap, Layout e Navigazione
L'utente avvia BigIDE con un comando e ottiene un ambiente tmux completo: 6 pannelli (5 pannelli + 1 pannello git-bar di 1 riga) con layout curato, navigazione da tastiera, status bar informative e tema elegante. Il flow state inizia qui.
**FRs:** FR1, FR2, FR4, FR5b, FR6, FR7, FR8, FR9, FR10, FR26, FR33, FR35, FR36, FR37, FR38, FR48

### Epic 2: Esplorazione File con Yazi
L'utente naviga il file system del progetto, visualizza anteprime di immagini e documenti Office/PDF, e modifica file con editor LazyVim overlay.
**FRs:** FR11, FR12, FR13, FR14, FR15

### Epic 3: Ambiente Intelligente — MCP Base
L'ambiente di sviluppo diventa intelligente: Claude Code può leggere qualsiasi pannello, inviare comandi e monitorare processi. Il differenziatore del prodotto.
**FRs:** FR16, FR17, FR18, FR19, FR20

### Epic 4: Preview Web con Chrome
L'utente e Claude Code aprono pagine web in Chrome con layout automatico (50/50 o fullscreen) accanto all'IDE. Dialog scelta layout alla prima apertura.
**FRs:** FR23, FR24, FR25

### Epic 5: Git Workflow dall'IDE
L'utente gestisce l'intero ciclo git senza uscire dall'IDE: branch switch con fuzzy search, commit con popup, push, log grafico e lazygit completo in overlay.
**FRs:** FR27, FR28, FR29, FR30, FR31, FR32

### Epic 6: Installazione Automatizzata e Manutenzione
BigIDE si installa automaticamente con un comando, verifica e installa tutte le dipendenze, e idempotente, riparabile (`--repair`), aggiornabile (`--update`) e con auto-recovery dei componenti (espansione FR41).
**FRs:** FR39, FR40, FR41, FR42

### Epic 7: Controllo Avanzato, Multi-Progetto e Monitoring
Claude Code gestisce dinamicamente pannelli (crea/chiude/ridimensiona), monitora cambiamenti con watch, l'utente lavora su piu progetti in tab separati e monitora il consumo token in tempo reale.
**FRs:** FR3, FR21, FR22, FR34

### Epic 8: Auto-Provisioning Nuovo Progetto
BigIDE rileva cartelle vuote e inizializza automaticamente: installa BMAD, esegue autoprovision da GitHub, crea il repository. Da zero a progetto senza frizione.
**FRs:** FR5

### Epic 9: Ambiente che Impara — Memoria Persistente
L'ambiente di sviluppo accumula conoscenza progetto per progetto, risolve errori già visti consultando la memoria e genera script di recovery riutilizzabili. L'IDE migliora con l'uso.
**FRs:** FR43, FR44, FR45, FR46

### Epic 10: Input Vocale
L'utente detta comandi con Whisper.cpp locale su Apple Silicon, zero costi token. Canale alternativo alla tastiera per accessibilita completa.
**FRs:** FR47

---

## Epic 1: L'IDE Prende Vita — Bootstrap, Layout e Navigazione

L'utente avvia BigIDE con un comando e ottiene un ambiente tmux completo: 6 pannelli (5 pannelli + 1 pannello git-bar di 1 riga) con layout curato, navigazione da tastiera, status bar informative e tema elegante. Il flow state inizia qui.

### Story 1.1: Struttura Progetto e Configurazione Isolata

As a sviluppatore,
I want una struttura progetto organizzata e una directory di configurazione runtime isolata (`~/.bigide/`),
So that tutte le configurazioni BigIDE siano separate da quelle personali e il progetto abbia fondamenta solide per ogni componente futuro.

**Acceptance Criteria:**

**Given** il repository BigIDE e clonato localmente
**When** viene eseguito lo script di setup iniziale
**Then** la struttura repository contiene `bin/`, `src/shell/lib/`, `src/mcp/`, `config/`, `tests/`
**And** la directory `~/.bigide/` viene creata con le sottodirectory: `tmux/`, `yazi/`, `nvim/`, `mcp/`, `layouts/`, `logs/`, `scripts/`

**Given** `~/.bigide/` non esiste
**When** lo script di setup viene eseguito
**Then** `~/.bigide/config.json` viene creato con valori di default e `"version": 1`
**And** `~/.bigide/layouts/default.json` viene copiato da `config/layouts/default.json`
**And** `~/.bigide/tmux/tmux.conf` viene copiato da `config/tmux.conf`
**And** `~/.bigide/gitmux.conf` viene copiato da `config/gitmux.conf`
**And** `~/.bigide/yazi/yazi.toml` viene copiato da `config/yazi/yazi.toml`

**Given** `~/.bigide/` esiste gia con configurazioni personalizzate dall'utente
**When** lo script di setup viene rieseguito
**Then** i file di configurazione esistenti NON vengono sovrascritti
**And** le directory mancanti vengono create senza toccare quelle esistenti

**Given** la configurazione e in `~/.bigide/`
**When** tmux, Yazi o Neovim vengono lanciati da BigIDE
**Then** ogni tool usa esclusivamente i file config da `~/.bigide/` (tmux via `-f`, Yazi via `YAZI_CONFIG_HOME`, Neovim via `NVIM_APPNAME`)
**And** le configurazioni globali dell'utente (`~/.tmux.conf`, `~/.config/yazi/`, ecc.) non vengono lette ne modificate

### Story 1.2: Layout Tmux Dichiarativo e Tema Visivo

As a sviluppatore,
I want un layout tmux a 6 pannelli (5 pannelli + 1 pannello git-bar di 1 riga) con proporzioni definite e un tema visivo curato,
So that l'ambiente di lavoro sia stabile, elegante e con ogni pannello al posto giusto fin dal primo avvio.

**Acceptance Criteria:**

**Given** il file `~/.bigide/layouts/default.json` esiste con la definizione del layout MVP
**When** la funzione `create_layout()` in `layout.sh` viene invocata con una sessione tmux attiva
**Then** vengono creati 6 pannelli: yazi (25%/70%), claude (75%/70%), monitor (15%/30%), log (35%/30%), terminal (50%/30%), git-bar (100%/1 riga)
**And** ogni pannello ha il processo corretto avviato (Yazi, Claude Code, shell per monitor, shell per log, zsh per terminale)
**And** la disposizione rispetta le proporzioni definite nel JSON

**Given** il file `default.json` e un JSON valido
**When** `layout.sh` lo interpreta con `jq`
**Then** i comandi tmux `split-window` e `resize-pane` vengono generati correttamente
**And** il layout risultante corrisponde alla definizione JSON

**Given** il layout e stato creato
**When** l'utente guarda lo schermo in Ghostty fullscreen
**Then** il tema tokyonight-night (o tema configurato) e applicato: bordi pannelli visibili, colori coerenti, sfondo scuro elegante
**And** i bordi tra pannelli hanno contrasto sufficiente per essere distinguibili (NFR8)

**Given** l'utente vuole cambiare il tema visivo
**When** modifica il campo `"theme"` in `~/.bigide/config.json`
**Then** al prossimo avvio di BigIDE il nuovo tema viene applicato a tmux e Ghostty
**And** la modifica non richiede intervento su altri file di configurazione

### Story 1.3: Script Bootstrap `bigide` con Splash Screen

As a sviluppatore,
I want avviare BigIDE con un singolo comando `bigide` e vedere una splash screen durante il caricamento,
So that l'esperienza di avvio sia fluida e io sappia sempre cosa sta succedendo.

**Acceptance Criteria:**

**Given** il comando `bigide` e in PATH e nessuna sessione BigIDE esiste
**When** l'utente esegue `bigide` (o `bigide ~/projects/mio-progetto`)
**Then** Ghostty viene lanciato in modalita fullscreen
**And** una splash screen ANSI appare con logo ASCII BigIDE e progress bar Unicode (`░▓`)
**And** la splash screen mostra ogni fase di avvio (es. "Creazione sessione tmux...", "Avvio pannelli...", "Caricamento layout...")
**And** al completamento, la splash screen scompare e il layout tmux completo e visibile

**Given** una sessione tmux BigIDE esiste gia per la directory corrente
**When** l'utente esegue `bigide`
**Then** BigIDE si riattacca alla sessione esistente senza crearne una nuova
**And** tutti i pannelli e processi sono nello stato in cui erano stati lasciati

**Given** Ghostty non e in fullscreen
**When** BigIDE viene avviato
**Then** Ghostty viene forzato in fullscreen tramite flag CLI o AppleScript
**And** il fullscreen viene mantenuto durante l'intera sessione

**Given** lo script `bigide` viene eseguito
**When** un errore critico si verifica durante l'avvio (es. tmux non installato)
**Then** un messaggio di errore chiaro viene mostrato con `die()`
**And** il messaggio indica quale dipendenza manca e come installarla
**And** lo script esce con codice diverso da 0

**Given** lo script `bigide` viene eseguito senza argomenti
**When** l'avvio procede
**Then** la directory di lavoro corrente viene usata come directory del progetto
**And** il nome della sessione tmux segue il pattern `bigide-{nome-directory}`

### Story 1.4: Navigazione Pannelli e Keybinding

As a sviluppatore con Parkinson,
I want navigare tra i pannelli con keybinding sequenziali e semplici,
So that possa muovermi nell'IDE senza sforzo motorio e senza toccare il mouse.

**Acceptance Criteria:**

**Given** BigIDE e attivo con il layout a 6 pannelli
**When** l'utente preme `prefix + freccia direzionale` (su/giu/sinistra/destra)
**Then** il focus si sposta al pannello adiacente nella direzione indicata
**And** il cambio di focus avviene in meno di 100ms (NFR3)

**Given** BigIDE e attivo con il layout a 6 pannelli
**When** l'utente preme `prefix + 1`
**Then** il focus si sposta al pannello Yazi (file browser)

**Given** BigIDE e attivo con il layout a 6 pannelli
**When** l'utente preme `prefix + 2`
**Then** il focus si sposta al pannello Claude Code

**Given** BigIDE e attivo con il layout a 6 pannelli
**When** l'utente preme `prefix + 3`
**Then** il focus si sposta al pannello Usage Monitor (Monitor)

**Given** BigIDE e attivo con il layout a 6 pannelli
**When** l'utente preme `prefix + 4`
**Then** il focus si sposta al pannello Log

**Given** BigIDE e attivo con il layout a 6 pannelli
**When** l'utente preme `prefix + 5`
**Then** il focus si sposta al pannello Terminale

**And** il pannello git-bar NON ha keybinding di navigazione numerica (è di sola lettura)

**Given** un pannello qualsiasi e in focus
**When** l'utente preme `prefix + z`
**Then** il pannello si espande a fullscreen (zoom tmux)
**And** premendo di nuovo `prefix + z` il layout torna alle proporzioni originali

**Given** Ghostty e in fullscreen e l'utente ridimensiona (es. uscita da fullscreen temporanea)
**When** il resize viene rilevato da tmux
**Then** le proporzioni dei pannelli vengono ribilanciate automaticamente tramite hook `after-resize-window`
**And** nessun pannello viene compresso sotto la dimensione minima leggibile

**Given** tutti i keybinding di navigazione
**When** vengono eseguiti
**Then** ogni keybinding e eseguibile con una sequenza (non chord simultaneo) per minimizzare lo sforzo motorio (NFR7)

### Story 1.5: Status Bar Superiore e Git Bar Inferiore

As a sviluppatore,
I want vedere informazioni di sistema e git sempre visibili nelle barre di stato,
So that abbia consapevolezza dell'ambiente senza dover eseguire comandi manuali.

**Nota architetturale:** La tmux status-bar è SOLO in alto (top bar) e mostra tab, CPU, RAM, ora. La git bar è un pannello tmux dedicato di 1 riga posizionato sotto Log/Terminal, NON la tmux status-bar inferiore.

**Acceptance Criteria:**

**Given** BigIDE e attivo con una sessione tmux
**When** l'utente guarda la barra superiore (tmux status-bar, posizione top)
**Then** vengono mostrati: lista tab/progetti aperti (a sinistra), uso CPU %, uso RAM %, data e ora (a destra)
**And** le informazioni sono leggibili con contrasto sufficiente (NFR8)

**Given** BigIDE e attivo in una directory con repository git
**When** l'utente guarda il pannello git-bar (pannello tmux dedicato di 1 riga, posizionato sotto Log/Terminal)
**Then** gitmux mostra: branch corrente, stato (clean/dirty), hash ultimo commit, messaggio commit, conteggio diff (+/-)
**And** le informazioni si aggiornano automaticamente dopo operazioni git

**Given** il campo `"statusInterval"` in `config.json` e impostato a N secondi
**When** BigIDE e in esecuzione
**Then** le status bar si aggiornano ogni N secondi
**And** l'aggiornamento non causa lag o impatto percepibile sugli altri pannelli (NFR5)

**Given** la directory corrente NON e un repository git
**When** l'utente guarda la barra inferiore
**Then** la barra git mostra un indicatore neutro (es. "No git repo") o resta vuota
**And** nessun errore viene generato

**Given** le barre di stato sono attive
**When** passa 1+ ora di sessione (NFR11)
**Then** le barre continuano a funzionare e aggiornarsi senza degradazione
**And** gli script di status non accumulano processi zombie o consumo memoria crescente

### Story 1.6: Which-Key Banner e Scopribilità Keybinding

As a sviluppatore (nuovo o esperto),
I want vedere i keybinding disponibili dopo aver premuto il prefix,
So that possa scoprire le funzionalità dell'IDE senza consultare documentazione.

**Acceptance Criteria:**

**Given** BigIDE è attivo e l'utente preme il prefix
**When** passano 500ms senza che venga premuto un secondo tasto
**Then** un banner compatto appare in basso a destra con i binding principali (frecce=navigate, z=zoom, g=git, b=browser, v=voice, ?=help)
**And** il banner usa sfondo `#1a1b26` con bordo `#283457`, tasti in `#7aa2f7`, descrizioni in `#c0caf5`

**Given** il which-key banner è visibile
**When** l'utente preme un qualsiasi tasto (incluso Escape)
**Then** il banner scompare immediatamente
**And** il tasto premuto viene eseguito normalmente

**Given** l'utente preme `prefix + ?`
**When** il keybinding viene riconosciuto
**Then** un popup tmux mostra la lista completa di tutti i keybinding disponibili
**And** il popup si chiude con `q` o Escape

**Given** il which-key banner è configurato
**When** viene mostrato
**Then** non copre il pannello Claude Code — resta nella zona inferiore destra
**And** è implementato tramite tmux `display-popup` con dimensioni compatte

---

## Epic 2: Esplorazione File con Yazi

L'utente naviga il file system del progetto, visualizza anteprime di immagini e documenti Office/PDF, e modifica file con editor LazyVim overlay.

### Story 2.1: File Browser Yazi con Navigazione e Anteprime Immagini

As a sviluppatore,
I want navigare i file del progetto con Yazi nel pannello dedicato e vedere anteprime delle immagini,
So that possa esplorare il progetto visivamente senza uscire dall'IDE.

**Acceptance Criteria:**

**Given** BigIDE e attivo e il pannello Yazi e visibile
**When** l'utente naviga con le frecce o i tasti vim (h/j/k/l) dentro Yazi
**Then** i file e le directory del progetto vengono mostrati con icone e colori appropriati
**And** la navigazione funziona interamente da tastiera (NFR6)

**Given** l'utente e nel pannello Yazi
**When** naviga con il mouse (click, scroll)
**Then** la selezione file segue il click e lo scroll funziona correttamente (NFR9)
**And** non sono richiesti movimenti precisi — i target di click sono ampi (NFR10)

**Given** l'utente seleziona un file immagine (PNG, JPG, GIF, SVG, WebP)
**When** il cursore e sul file
**Then** un'anteprima dell'immagine viene renderizzata nel pannello preview di Yazi
**And** il rendering usa il Kitty Graphics Protocol supportato da Ghostty

**Given** Yazi e configurato con `YAZI_CONFIG_HOME=~/.bigide/yazi`
**When** Yazi viene lanciato nel pannello
**Then** usa esclusivamente la configurazione BigIDE (`yazi.toml`, `keymap.toml`)
**And** le configurazioni personali dell'utente in `~/.config/yazi/` non vengono lette

**Given** il pannello Yazi e attivo
**When** l'utente preme Enter su una directory
**Then** Yazi entra nella directory mostrando i contenuti
**And** la navigazione e fluida senza ritardi percepibili

### Story 2.2: Anteprime Documenti Office e PDF via Quick Look

As a sviluppatore,
I want vedere anteprime di PDF e documenti Office direttamente nel file browser,
So that possa verificare il contenuto di documenti senza aprire applicazioni esterne.

**Acceptance Criteria:**

**Given** il custom previewer `ql-preview.sh` e configurato in Yazi
**When** l'utente seleziona un file PDF
**Then** `qlmanage -t -s 800 -o /tmp/yazi-previews/` genera un thumbnail PNG del documento
**And** Yazi mostra il thumbnail nel pannello anteprima via Kitty Graphics Protocol

**Given** l'utente seleziona un file Office (DOC, DOCX, XLS, XLSX, PPT, PPTX, Pages, Numbers, Keynote)
**When** il cursore e sul file
**Then** Quick Look genera un thumbnail del documento
**And** l'anteprima viene mostrata nel pannello preview di Yazi

**Given** un file non supportato da Quick Look (es. file binario sconosciuto)
**When** l'utente lo seleziona
**Then** Yazi mostra l'anteprima di fallback (testo, hex, o messaggio "anteprima non disponibile")
**And** nessun errore viene generato

**Given** la directory `/tmp/yazi-previews/` non esiste
**When** `ql-preview.sh` viene invocato
**Then** la directory viene creata automaticamente
**And** i thumbnail generati vengono salvati correttamente

### Story 2.3: Editor LazyVim Overlay da Yazi

As a sviluppatore,
I want aprire un file nell'editor LazyVim direttamente da Yazi e tornare al file browser dopo aver salvato,
So that possa fare modifiche rapide ai file senza uscire dal flusso di navigazione.

**Acceptance Criteria:**

**Given** l'utente e nel pannello Yazi con un file di testo selezionato
**When** preme Enter (o il keybinding configurato) sul file
**Then** LazyVim si apre in overlay (popup tmux o sostituzione temporanea del pannello) con il file caricato
**And** LazyVim usa la configurazione BigIDE (`NVIM_APPNAME=bigide` o `-u ~/.bigide/nvim/init.lua`)

**Given** LazyVim e aperto in overlay con un file
**When** l'utente modifica il file, salva (`:w`) e chiude (`:q` o `:wq`)
**Then** l'overlay si chiude e Yazi torna visibile
**And** il file risulta aggiornato nel filesystem
**And** Yazi riflette eventuali cambiamenti (es. dimensione file aggiornata)

**Given** LazyVim e aperto in overlay
**When** l'utente chiude senza salvare (`:q!`)
**Then** le modifiche vengono scartate
**And** l'overlay si chiude e Yazi torna visibile con il file invariato

**Given** LazyVim e configurato per BigIDE
**When** viene aperto
**Then** le configurazioni personali di Neovim dell'utente (`~/.config/nvim/`) non vengono toccate
**And** i plugin LazyVim essenziali sono disponibili (syntax highlighting, line numbers, basic editing)

---

## Epic 3: Ambiente Intelligente — MCP Base

L'ambiente di sviluppo diventa intelligente: Claude Code può leggere qualsiasi pannello, inviare comandi e monitorare processi. Il differenziatore del prodotto.

### Story 3.1: Scaffold MCP Server e Infrastruttura

As a sviluppatore,
I want un server MCP TypeScript funzionante con infrastruttura solida (wrapper tmux, error handling, logging),
So that ogni tool futuro possa essere costruito su fondamenta affidabili e coerenti.

**Acceptance Criteria:**

**Given** il progetto MCP non esiste ancora
**When** viene eseguito `npx @modelcontextprotocol/create-server tmux-mcp` in `src/mcp/`
**Then** viene creato un progetto TypeScript con `package.json`, `tsconfig.json`, entry point e struttura base
**And** le dipendenze `@modelcontextprotocol/sdk`, `typescript`, `zod` sono presenti

**Given** il progetto MCP e inizializzato
**When** viene creato il modulo `tmux/client.ts` (`TmuxClient`)
**Then** espone metodi per eseguire comandi tmux via `child_process.execSync`
**And** ogni comando tmux passa esclusivamente attraverso `TmuxClient` — mai chiamate dirette nei tool
**And** errori di esecuzione tmux vengono catturati e wrappati in errori strutturati

**Given** il modulo `utils/errors.ts` e implementato
**When** un tool incontra un errore
**Then** viene restituito un oggetto con `{ error: { code: ErrorCode, message: string } }`
**And** i codici supportati sono: `PANE_NOT_FOUND`, `SESSION_NOT_FOUND`, `COMMAND_TIMEOUT`, `TMUX_ERROR`, `INVALID_PARAMS`

**Given** il modulo `utils/logger.ts` e implementato
**When** un tool viene invocato
**Then** l'invocazione viene loggata in `~/.bigide/logs/mcp.log` con timestamp, nome tool e parametri
**And** errori critici vengono scritti anche su stderr
**And** il formato e `[LEVEL] [mcp] message`

**Given** il server MCP e compilato (`tsc` → `dist/index.js`)
**When** viene registrato in `~/.claude/settings.json` come `tmux-mcp` con trasporto stdio
**Then** Claude Code riconosce il server e puo elencare i tool disponibili
**And** la registrazione non richiede configurazione manuale dopo il setup iniziale (NFR16)

**Given** il server MCP e in esecuzione
**When** un errore gestibile si verifica in un tool
**Then** il server NON crasha — logga l'errore e restituisce risposta strutturata (fail-open)
**And** il server resta disponibile per le invocazioni successive (NFR12)

### Story 3.2: Tool `capture_pane` con ANSI Stripping

As a Claude Code (agente AI),
I want catturare il contenuto visibile di qualsiasi pannello tmux con output pulito,
So that possa leggere log, output di build e risultati di comandi senza rumore ANSI.

**Acceptance Criteria:**

**Given** il tool `tmux_capture_pane` e registrato nel server MCP
**When** Claude Code invoca `tmux_capture_pane` con `target_pane` valido
**Then** il contenuto visibile del pannello viene catturato tramite `TmuxClient`
**And** il risultato viene restituito come testo pulito
**And** l'operazione si completa in meno di 500ms (NFR1)

**Given** l'output catturato contiene codici ANSI (colori, escape sequences)
**When** il risultato viene processato
**Then** `utils/ansi.ts` rimuove tutti i codici ANSI con regex
**And** il testo risultante e leggibile e privo di artefatti

**Given** il parametro `lines` e specificato (es. 50)
**When** `capture_pane` viene invocato
**Then** vengono restituite le ultime N righe del pannello
**And** il default e 50 righe se `lines` non e specificato

**Given** i parametri `start` e `end` sono specificati
**When** `capture_pane` viene invocato
**Then** viene restituito il range di righe specificato dal buffer del pannello

**Given** `target_pane` punta a un pannello che non esiste
**When** `capture_pane` viene invocato
**Then** viene restituito un errore strutturato con codice `PANE_NOT_FOUND`
**And** il messaggio include l'ID del pannello richiesto

**Given** tmux non e in esecuzione
**When** `capture_pane` viene invocato
**Then** viene restituito un errore con codice `TMUX_ERROR`
**And** il messaggio indica che tmux non e raggiungibile

### Story 3.3: Tool `send_keys` con Wait-for-Prompt

As a Claude Code (agente AI),
I want inviare comandi a qualsiasi pannello e attendere che il comando sia completato prima di ricevere il risultato,
So that possa orchestrare sequenze di comandi senza race condition.

**Acceptance Criteria:**

**Given** il tool `tmux_send_keys` e registrato nel server MCP
**When** Claude Code invoca `send_keys` con `target_pane` e `keys` validi
**Then** la sequenza di tasti viene inviata al pannello tramite `TmuxClient`
**And** l'invocazione viene loggata con timestamp, target e contenuto inviato

**Given** il parametro `enter` e `true` (default)
**When** `send_keys` viene invocato con un comando (es. `"ls -la"`)
**Then** il comando viene inviato seguito da Enter
**And** il meccanismo wait-for-prompt si attiva

**Given** wait-for-prompt e attivo
**When** il comando e stato inviato
**Then** il server esegue polling con `capture_pane` ogni 100-200ms
**And** cerca il pattern del prompt shell (configurabile, default `$` o `❯`)
**And** quando il prompt riappare, restituisce l'output del comando
**And** l'intera operazione si completa in meno di 500ms per comandi rapidi (NFR1)

**Given** wait-for-prompt e attivo e il comando impiega piu di 5 secondi
**When** il timeout viene raggiunto (NFR2)
**Then** viene restituito l'output catturato fino a quel momento
**And** un flag `timeout: true` segnala che il comando potrebbe non essere completato

**Given** il parametro `enter` e `false`
**When** `send_keys` viene invocato
**Then** i tasti vengono inviati senza Enter e senza wait-for-prompt
**And** utile per sequenze parziali o tasti speciali (Ctrl+C, Escape, ecc.)

**Given** `target_pane` non esiste
**When** `send_keys` viene invocato
**Then** viene restituito errore `PANE_NOT_FOUND`
**And** nessun tasto viene inviato

**Given** Claude Code invia comandi rapidi in sequenza allo stesso pannello
**When** ogni `send_keys` usa wait-for-prompt
**Then** ogni comando attende il completamento del precedente prima di inviare il successivo
**And** non si verificano sovrapposizioni di comandi

### Story 3.4: Tool `list_panes` e Panoramica Sessione

As a Claude Code (agente AI),
I want elencare tutti i pannelli della sessione con informazioni dettagliate,
So that possa identificare il pannello giusto per catturare output o inviare comandi.

**Acceptance Criteria:**

**Given** il tool `tmux_list_panes` e registrato nel server MCP
**When** Claude Code invoca `list_panes`
**Then** viene restituita una lista di tutti i pannelli della sessione BigIDE corrente
**And** ogni pannello include: id tmux, nome logico (yazi, claude, monitor, log, terminal, git-bar), dimensioni (righe x colonne), processo attivo, stato (attivo/inattivo)

**Given** la sessione BigIDE ha 6 pannelli nel layout MVP
**When** `list_panes` viene invocato
**Then** vengono restituiti esattamente 6 pannelli con i nomi logici corretti
**And** le dimensioni riflettono le proporzioni reali del layout

**Given** un pannello ha un processo in esecuzione (es. `node` per Claude Code, `yazi` per file browser)
**When** `list_panes` viene invocato
**Then** il campo processo attivo mostra il nome del processo corrente
**And** il parsing dell'output tmux `list-panes` e gestito da `tmux/parser.ts`

**Given** la sessione tmux non esiste
**When** `list_panes` viene invocato
**Then** viene restituito errore `SESSION_NOT_FOUND`

**Given** la sessione ha piu finestre (tab/progetti)
**When** `list_panes` viene invocato senza parametri
**Then** vengono restituiti i pannelli della finestra attiva
**And** un parametro opzionale `window` permette di specificare una finestra diversa

---

## Epic 4: Preview Web con Chrome

L'utente e Claude Code aprono pagine web in Chrome con layout automatico (50/50 o fullscreen) accanto all'IDE. Dialog scelta layout alla prima apertura.

### Story 4.1: Tool MCP `open_browser` e Apertura Chrome

As a Claude Code (agente AI),
I want aprire un URL in Chrome tramite MCP,
So that possa mostrare preview web, documentazione o risultati di build all'utente senza che debba copiare URL manualmente.

**Acceptance Criteria:**

**Given** il tool `open_browser` e registrato nel server MCP
**When** Claude Code invoca `open_browser` con un `url` valido
**Then** Chrome viene aperto (o attivato se gia aperto) con l'URL specificato
**And** l'apertura avviene tramite `utils/applescript.ts` con AppleScript
**And** l'operazione viene loggata in `mcp.log`

**Given** Chrome non e installato sul sistema
**When** `open_browser` viene invocato
**Then** viene restituito un errore strutturato con codice `APPLESCRIPT_ERROR`
**And** il messaggio indica che Chrome non e stato trovato

**Given** Chrome e gia aperto con altre tab
**When** `open_browser` viene invocato
**Then** l'URL viene aperto in una nuova tab di Chrome
**And** le tab esistenti non vengono chiuse o modificate

**Given** l'URL fornito non e valido
**When** `open_browser` viene invocato
**Then** viene restituito un errore con codice `INVALID_PARAMS`
**And** il messaggio indica il formato URL atteso

**Given** il sistema operativo e macOS Ventura o successivo
**When** `open_browser` esegue AppleScript
**Then** l'esecuzione funziona correttamente senza errori di permessi (NFR18)

### Story 4.2: Scelta Layout Browser e Posizionamento Automatico

As a sviluppatore,
I want scegliere come posizionare Chrome rispetto all'IDE alla prima apertura della sessione,
So that possa lavorare con il browser accanto senza dover riposizionare finestre manualmente.

**Acceptance Criteria:**

**Given** e la prima volta nella sessione che il browser viene aperto
**When** `open_browser` viene invocato
**Then** un dialog AppleScript appare con due opzioni: "50/50" e "Fullscreen separato"
**And** l'utente seleziona la preferenza

**Given** l'utente sceglie "50/50"
**When** la scelta viene confermata
**Then** Ghostty viene ridimensionato alla meta sinistra dello schermo
**And** Chrome viene posizionato nella meta destra dello schermo
**And** entrambe le finestre occupano il 50% della larghezza e il 100% dell'altezza
**And** la preferenza `"browserLayout": "split"` viene salvata in `config.json`

**Given** l'utente sceglie "Fullscreen separato"
**When** la scelta viene confermata
**Then** Chrome viene messo in fullscreen (space separato o stessa area)
**And** Ghostty resta in fullscreen
**And** l'utente puo switchare con Cmd+Tab
**And** la preferenza `"browserLayout": "fullscreen"` viene salvata in `config.json`

**Given** il browser e gia stato aperto nella sessione corrente (preferenza salvata)
**When** `open_browser` viene invocato di nuovo
**Then** il dialog NON riappare
**And** il layout precedentemente scelto viene applicato automaticamente
**And** Chrome si apre nella posizione corretta

**Given** l'utente vuole cambiare la preferenza
**When** modifica `"browserLayout"` in `config.json`
**Then** alla prossima sessione il nuovo layout viene applicato
**And** durante la sessione corrente puo forzare il dialog con un parametro opzionale

---

## Epic 5: Git Workflow dall'IDE

L'utente gestisce l'intero ciclo git senza uscire dall'IDE: branch switch con fuzzy search, commit con popup, push, log grafico e lazygit completo in overlay.

### Story 5.1: Git Key Table e Branch Switch con Fuzzy Search

As a sviluppatore,
I want cambiare branch con una selezione fuzzy senza uscire dall'IDE,
So that possa navigare tra branch rapidamente con la tastiera.

**Acceptance Criteria:**

**Given** BigIDE e attivo e tmux >= 3.3 e installato
**When** l'utente preme `prefix + g`
**Then** tmux attiva la key table `git-table`
**And** i tasti successivi vengono interpretati come azioni git
**And** la key table ha un timeout ragionevole (es. 2s) dopo il quale torna alla tabella normale

**Given** la key table `git-table` e attiva
**When** l'utente preme `b`
**Then** un popup tmux (`display-popup`) appare con la lista dei branch filtrata da fzf
**And** l'utente puo cercare branch digitando nel fuzzy finder

**Given** il popup fzf mostra i branch disponibili
**When** l'utente seleziona un branch e preme Enter
**Then** `git checkout` viene eseguito sul branch selezionato
**And** il popup si chiude
**And** la git bar inferiore si aggiorna mostrando il nuovo branch

**Given** il popup fzf e aperto
**When** l'utente preme Escape o Ctrl+C
**Then** il popup si chiude senza cambiare branch
**And** il focus torna al pannello precedente

**Given** la directory corrente non e un repository git
**When** l'utente preme `prefix + g b`
**Then** il popup mostra un messaggio di errore chiaro (es. "Not a git repository")
**And** il popup si chiude automaticamente o con un tasto

### Story 5.2: Commit, Push e Status in Popup

As a sviluppatore,
I want creare commit, eseguire push e vedere status/log git tramite keybinding dedicati,
So that possa gestire il ciclo git completo senza digitare comandi manuali.

**Acceptance Criteria:**

**Given** la key table `git-table` e attiva
**When** l'utente preme `c`
**Then** un popup tmux appare con un prompt per il messaggio di commit
**And** `git add -A` viene eseguito prima del commit

**Given** il popup commit e visibile
**When** l'utente digita il messaggio e preme Enter
**Then** `git commit -m "messaggio"` viene eseguito
**And** il popup mostra il risultato del commit (successo o errore)
**And** la git bar inferiore si aggiorna

**Given** la key table `git-table` e attiva
**When** l'utente preme `p`
**Then** `git push` viene inviato al pannello terminale tramite `send-keys`
**And** l'output del push e visibile nel pannello terminale
**And** la git bar si aggiorna dopo il completamento

**Given** la key table `git-table` e attiva
**When** l'utente preme `s`
**Then** un popup tmux mostra `git status`
**And** il popup si chiude con qualsiasi tasto o Escape

**Given** la key table `git-table` e attiva
**When** l'utente preme `l`
**Then** un popup tmux mostra `git log --oneline --graph -20`
**And** l'utente puo scrollare il log nel popup
**And** il popup si chiude con `q` o Escape

**Given** non ci sono modifiche da committare
**When** l'utente preme `prefix + g c`
**Then** il popup mostra "nothing to commit, working tree clean"
**And** nessun commit vuoto viene creato

### Story 5.3: Lazygit Completo e Interazione Mouse

As a sviluppatore,
I want aprire lazygit in un popup grande per operazioni git complesse e usare il mouse nei popup,
So that possa gestire merge, rebase e operazioni avanzate con un'interfaccia completa.

**Acceptance Criteria:**

**Given** la key table `git-table` e attiva e lazygit e installato
**When** l'utente preme `g`
**Then** un popup tmux si apre con dimensioni 80% larghezza x 80% altezza
**And** lazygit viene lanciato nel popup con la directory del progetto corrente

**Given** lazygit e aperto nel popup
**When** l'utente naviga con tastiera (tasti vim, Enter, Escape)
**Then** tutte le funzionalita di lazygit sono disponibili: staging, commit, branch, merge, rebase, stash, log
**And** le operazioni git vengono eseguite nel contesto del progetto

**Given** lazygit e aperto nel popup
**When** l'utente interagisce con il mouse (click su pannelli lazygit, scroll)
**Then** il mouse funziona correttamente dentro il popup (NFR9)
**And** non sono richiesti movimenti precisi — i target sono ampi (NFR10)

**Given** lazygit e aperto nel popup
**When** l'utente chiude lazygit (con `q`)
**Then** il popup si chiude
**And** il focus torna al pannello precedente
**And** la git bar inferiore si aggiorna con eventuali cambiamenti

**Given** lazygit non e installato
**When** l'utente preme `prefix + g g`
**Then** il popup mostra un messaggio: "lazygit non trovato. Installa con: brew install lazygit"
**And** il popup si chiude con qualsiasi tasto

**Given** un qualsiasi popup git e aperto (status, log, commit, lazygit)
**When** l'utente usa il mouse per scrollare o cliccare
**Then** l'interazione mouse e supportata dove il tool sottostante lo permette (NFR9)
**And** il click fuori dal popup non causa comportamenti inattesi

---

## Epic 6: Installazione Automatizzata e Manutenzione

BigIDE si installa automaticamente con un comando, verifica e installa tutte le dipendenze, e idempotente, riparabile (`--repair`) e aggiornabile (`--update`).

### Story 6.1: Verifica e Installazione Automatica Dipendenze

As a sviluppatore su un Mac,
I want che BigIDE verifichi e installi automaticamente tutte le dipendenze al primo avvio,
So that possa partire da un Mac pulito e avere tutto funzionante senza dover installare nulla manualmente.

**Acceptance Criteria:**

**Given** il comando `bigide` viene eseguito su un Mac senza dipendenze installate
**When** lo script `deps.sh` viene invocato
**Then** ogni dipendenza viene verificata con `command -v`
**And** le dipendenze mancanti vengono installate nell'ordine corretto

**Given** brew non e installato
**When** lo script rileva l'assenza di brew
**Then** brew viene installato automaticamente tramite lo script ufficiale di Homebrew
**And** il progresso viene comunicato all'utente con messaggi chiari

**Given** brew e disponibile
**When** le dipendenze brew sono mancanti
**Then** vengono installati: tmux, node, neovim, yazi, gitmux, lazygit, fzf, ffmpegthumbnailer, imagemagick
**And** ogni installazione mostra stato di avanzamento
**And** errori di installazione vengono segnalati senza bloccare le dipendenze successive

**Given** Node.js e disponibile
**When** Claude Code non e installato
**Then** `npm install -g @anthropic-ai/claude-code` viene eseguito
**And** il completamento viene verificato con `command -v claude`

**Given** Python/uv e disponibile
**When** claude-monitor non e installato
**Then** `uv tool install claude-monitor` viene eseguito

**Given** tutte le dipendenze sono gia installate
**When** `bigide` viene rieseguito
**Then** ogni dipendenza viene verificata ma NON reinstallata (NFR14)
**And** il messaggio indica "gia installato" per ogni check superato
**And** il tempo di verifica e minimale

**Given** una dipendenza cambia versione dopo un aggiornamento
**When** `bigide` viene eseguito
**Then** BigIDE funziona con la nuova versione se compatibile (NFR19)
**And** se una dipendenza non e piu compatibile, un messaggio chiaro indica il problema e la versione minima richiesta

**Given** Ghostty non e installato
**When** lo script rileva l'assenza
**Then** viene mostrato un messaggio con istruzioni per scaricare Ghostty dal sito ufficiale (non disponibile via brew)
**And** lo script prosegue con le altre dipendenze

### Story 6.2: Repair MCP e Recovery Senza Perdita Sessione

As a sviluppatore,
I want riparare il server MCP senza perdere la sessione di lavoro,
So that un problema MCP non interrompa la mia sessione e non debba ripartire da zero.

**Acceptance Criteria:**

**Given** BigIDE e attivo e il server MCP non risponde
**When** l'utente esegue `bigide --repair`
**Then** lo script `repair.sh` identifica il processo MCP (figlio di Claude Code)
**And** Claude Code nel pannello viene riavviato (send-keys `exit` + rilancio)
**And** il server MCP viene riavviato automaticamente come processo figlio

**Given** `bigide --repair` viene eseguito
**When** il repair procede
**Then** la sessione tmux resta intatta — nessun pannello viene chiuso o ricreato
**And** tutti i processi negli altri pannelli (Yazi, terminale, log, monitor) continuano a funzionare
**And** solo il pannello Claude Code viene toccato

**Given** il repair e completato
**When** il server MCP e riavviato
**Then** un health check verifica che il server risponde correttamente
**And** il risultato viene loggato in `~/.bigide/logs/bigide.log`
**And** un messaggio di conferma viene mostrato all'utente

**Given** il repair fallisce (es. Claude Code non si riavvia)
**When** l'errore viene rilevato
**Then** un messaggio di errore chiaro viene mostrato con suggerimenti per la risoluzione manuale
**And** l'errore viene loggato con dettagli diagnostici

**Given** BigIDE non e attivo (nessuna sessione tmux)
**When** l'utente esegue `bigide --repair`
**Then** viene mostrato un messaggio: "Nessuna sessione BigIDE attiva da riparare"
**And** lo script esce con codice 1

### Story 6.3: Aggiornamento BigIDE con Singolo Comando

As a sviluppatore,
I want aggiornare BigIDE e le sue dipendenze con un singolo comando,
So that possa avere sempre l'ultima versione senza procedure manuali.

**Acceptance Criteria:**

**Given** BigIDE e installato
**When** l'utente esegue `bigide --update`
**Then** lo script `update.sh` verifica la versione corrente e l'ultima disponibile su GitHub
**And** se disponibile, scarica la nuova versione

**Given** una nuova versione e disponibile
**When** l'aggiornamento procede
**Then** i file script (`bin/bigide`, `src/shell/lib/`) vengono aggiornati
**And** il bundle MCP compilato (`~/.bigide/mcp/tmux-mcp/dist/`) viene aggiornato
**And** i file di configurazione dell'utente in `~/.bigide/` NON vengono sovrascritti
**And** nuovi file di configurazione vengono aggiunti se necessari

**Given** le dipendenze esterne (tmux, Yazi, ecc.) hanno aggiornamenti disponibili
**When** `bigide --update` viene eseguito
**Then** le dipendenze brew vengono aggiornate con `brew upgrade`
**And** Claude Code viene aggiornato con `npm update -g @anthropic-ai/claude-code`
**And** ogni aggiornamento mostra il risultato (aggiornato / gia all'ultima versione / errore)

**Given** BigIDE e gia all'ultima versione
**When** `bigide --update` viene eseguito
**Then** viene mostrato "BigIDE e gia all'ultima versione"
**And** le dipendenze vengono comunque verificate per aggiornamenti

**Given** l'aggiornamento fallisce a meta (es. rete assente)
**When** l'errore viene rilevato
**Then** il sistema resta nella versione precedente funzionante
**And** nessuno stato inconsistente viene creato
**And** un messaggio indica cosa e fallito e come riprovare

### Story 6.4: Auto-Recovery e Messaggi di Stato nel Log

As a sviluppatore,
I want che BigIDE rilevi e ripari automaticamente i componenti che smettono di funzionare,
So that il mio flow non venga interrotto da problemi tecnici risolvibili automaticamente.

**Acceptance Criteria:**

**Given** il server MCP smette di rispondere durante una sessione
**When** il sistema rileva il fallimento
**Then** Claude Code nel pannello viene riavviato automaticamente (exit + relaunch)
**And** il server MCP si riavvia come processo figlio
**And** una riga nel pannello Log mostra `[HH:MM:SS] ✓ MCP server recovered`

**Given** claude-monitor nel pannello Monitor crasha
**When** il sistema rileva il pannello vuoto
**Then** claude-monitor viene rilanciato automaticamente
**And** una riga nel pannello Log mostra `[HH:MM:SS] ✓ Monitor restarted`

**Given** l'auto-recovery fallisce dopo 1 retry
**When** il componente non si ripristina
**Then** una riga nel pannello Log mostra `[HH:MM:SS] ✗ {componente} repair failed — run bigide --repair`
**And** gli altri pannelli NON vengono toccati (fail-open)

**Given** qualsiasi evento di recovery avviene
**When** il messaggio viene scritto nel Log
**Then** usa il formato: timestamp in grigio `#565f89`, `✓` verde `#9ece6a` per successo, `✗` rosso `#f7768e` per errore, `⚠` arancio `#ff9e64` per warning

---

## Epic 7: Controllo Avanzato, Multi-Progetto e Monitoring

Claude Code gestisce dinamicamente pannelli (crea/chiude/ridimensiona), monitora cambiamenti con watch, l'utente lavora su piu progetti in tab separati e monitora il consumo token in tempo reale.

### Story 7.1: Tool MCP `create_pane`, `close_pane` e `resize_pane`

As a Claude Code (agente AI),
I want creare, chiudere e ridimensionare pannelli tmux dinamicamente,
So that possa adattare l'ambiente di lavoro alle esigenze del momento senza intervento manuale dell'utente.

**Acceptance Criteria:**

**Given** il tool `tmux_create_pane` e registrato nel server MCP
**When** Claude Code invoca `create_pane` con `target_window`, `direction` (horizontal/vertical), `size` (percentuale) e `command` opzionale
**Then** un nuovo pannello viene creato con split nella direzione e dimensione specificate
**And** se `command` e fornito, il comando viene avviato nel nuovo pannello
**And** viene restituito l'ID del nuovo pannello

**Given** il tool `tmux_close_pane` e registrato nel server MCP
**When** Claude Code invoca `close_pane` con un `target_pane` che ha un processo attivo
**Then** il response include un avviso: "Pannello ha un processo attivo: {nome_processo}"
**And** il pannello viene chiuso
**And** il layout si ribilancia automaticamente

**Given** Claude Code invoca `close_pane` su un pannello inesistente
**When** l'operazione viene eseguita
**Then** viene restituito errore `PANE_NOT_FOUND`

**Given** il tool `tmux_resize_pane` e registrato nel server MCP
**When** Claude Code invoca `resize_pane` con `target_pane`, `direction` (U/D/L/R) e `amount` (righe o colonne)
**Then** il pannello viene ridimensionato nella direzione specificata
**And** i pannelli adiacenti si adattano di conseguenza

**Given** un'operazione di gestione pannelli viene eseguita
**When** l'operazione si completa
**Then** avviene in meno di 500ms (NFR1)
**And** viene loggata in `mcp.log`

### Story 7.2: Tool MCP `watch_pane` con Rilevamento Differenze

As a Claude Code (agente AI),
I want monitorare un pannello con catture periodiche e ricevere notifiche quando il contenuto cambia,
So that possa reagire automaticamente a eventi come completamento build, errori o output di test.

**Acceptance Criteria:**

**Given** il tool `tmux_watch_pane` e registrato nel server MCP
**When** Claude Code invoca `watch_pane` con `target_pane` e `interval` (es. 2000ms)
**Then** il server inizia a catturare il contenuto del pannello a intervalli regolari
**And** ogni cattura viene confrontata con la precedente

**Given** il watch e attivo su un pannello
**When** il contenuto cambia rispetto alla cattura precedente
**Then** il diff viene restituito a Claude Code
**And** il diff evidenzia le righe aggiunte/rimosse/modificate

**Given** il parametro `pattern` e specificato (es. `"error"`, `"BUILD SUCCESS"`)
**When** il pattern appare nel contenuto del pannello
**Then** una notifica immediata viene restituita a Claude Code con il contesto (righe circostanti)
**And** il watch continua a monitorare

**Given** il watch e attivo
**When** Claude Code vuole interrompere il monitoraggio
**Then** una invocazione con parametro `stop: true` ferma il watch
**And** le risorse vengono rilasciate

**Given** il watch e attivo per piu di 1 ora (NFR11)
**When** il monitoraggio continua
**Then** nessuna degradazione di performance o memory leak
**And** le catture continuano a intervalli regolari

**Given** il pannello monitorato viene chiuso
**When** la cattura successiva fallisce
**Then** il watch si ferma automaticamente
**And** un messaggio informa Claude Code che il pannello non esiste piu

### Story 7.3: Multi-Progetto con Tab Tmux

As a sviluppatore,
I want aprire nuovi progetti in tab separati dall'interno dell'IDE,
So that possa lavorare su piu progetti contemporaneamente senza uscire da BigIDE.

**Acceptance Criteria:**

**Given** BigIDE e attivo con almeno un progetto aperto
**When** l'utente preme il keybinding dedicato per nuovo progetto (es. `prefix + c` o keybinding custom)
**Then** viene chiesto il percorso del nuovo progetto
**And** l'utente puo digitare o selezionare il percorso

**Given** l'utente ha specificato un percorso valido
**When** conferma la creazione
**Then** un nuovo tab tmux viene creato con il nome della directory del progetto
**And** il layout completo a 6 pannelli viene ricreato nel nuovo tab
**And** ogni pannello viene avviato con il contesto del nuovo progetto (Yazi nella directory, Claude Code nella directory, ecc.)

**Given** il nuovo tab e stato creato
**When** l'utente guarda la status bar superiore
**Then** il nuovo tab appare nella lista dei progetti
**And** l'utente puo switchare tra tab con `prefix + n/p` (successivo/precedente) o `prefix + w` (lista)

**Given** piu tab/progetti sono aperti
**When** ogni tab ha la propria istanza Claude Code
**Then** ogni istanza opera nel contesto del proprio progetto
**And** le istanze sono indipendenti

**Given** l'utente vuole chiudere un tab progetto
**When** chiude il tab tmux
**Then** tutti i pannelli e processi del tab vengono terminati
**And** gli altri tab non vengono impattati
**And** BigIDE resta attivo se almeno un tab e aperto

### Story 7.4: Pannello Usage Monitor con Claude-Monitor

As a sviluppatore,
I want monitorare il consumo token di Claude Code in tempo reale nel pannello dedicato,
So that possa gestire il mio budget e sapere quando sto per raggiungere il limite.

**Acceptance Criteria:**

**Given** BigIDE e attivo e claude-monitor e installato
**When** il pannello Usage Monitor viene avviato
**Then** `claude-monitor --plan max5 --theme dark --refresh-rate 10` viene eseguito nel pannello
**And** il monitor mostra: consumo token corrente, progress bar colorata, burn rate stimato, predizione esaurimento

**Given** claude-monitor e in esecuzione
**When** Claude Code consuma token
**Then** il monitor si aggiorna in tempo reale (ogni 10 secondi)
**And** la progress bar riflette il consumo attuale rispetto al limite del piano

**Given** il consumo si avvicina al limite del piano
**When** la soglia critica viene raggiunta (es. >80%)
**Then** la progress bar cambia colore (da verde a giallo a rosso)
**And** l'utente ha visibilita immediata del rischio

**Given** claude-monitor non e installato
**When** BigIDE avvia il pannello Usage Monitor
**Then** il pannello mostra un messaggio: "claude-monitor non trovato. Installa con: uv tool install claude-monitor"
**And** il pannello resta attivo con shell vuota per uso manuale

**Given** il piano Claude dell'utente e diverso da max5
**When** l'utente modifica `"claudePlan"` in `config.json` (es. `"max20"`, `"pro"`)
**Then** claude-monitor viene avviato con il piano corretto
**And** le soglie e predizioni riflettono il piano selezionato

**Given** claude-monitor crasha o si blocca
**When** l'errore si verifica
**Then** gli altri pannelli non vengono impattati (NFR12)
**And** l'utente puo riavviare manualmente claude-monitor dal pannello

---

## Epic 8: Auto-Provisioning Nuovo Progetto

BigIDE rileva cartelle vuote e inizializza automaticamente: installa BMAD, esegue autoprovision da GitHub, crea il repository. Da zero a progetto senza frizione.

**Principio di design:** L'inizializzazione avviene tramite script sequenziale, NON tramite AI. Ovunque nel progetto sia possibile risparmiare token eseguendo una procedura scritta con uno script invece di chiedere all'intelligenza artificiale, si preferisce lo script.

### Story 8.1: Rilevamento Cartella Vuota e Inizializzazione Automatica Progetto

As a sviluppatore,
I want che BigIDE rilevi una cartella vuota e mi guidi nell'inizializzazione di un nuovo progetto con uno script sequenziale,
So that possa partire da zero senza procedure manuali e senza consumare token AI per operazioni automatizzabili.

**Acceptance Criteria:**

**Given** BigIDE viene avviato su una directory vuota (nessun file, o solo file nascosti come `.DS_Store`)
**When** lo script di bootstrap rileva l'assenza di progetto
**Then** un prompt testuale appare nel terminale: "Cartella vuota rilevata. Vuoi inizializzare un nuovo progetto? [s/n]"
**And** il prompt e generato dallo script bash, NON da Claude Code (risparmio token)

**Given** l'utente conferma l'inizializzazione
**When** lo script procede
**Then** vengono poste 4 domande sequenziali via `read -p` in bash:
**And** 1. "Nome progetto:"
**And** 2. "Tipo progetto (web/api/script/altro):"
**And** 3. "Installare BMAD? [s/n]:"
**And** 4. "Creare repository GitHub? [s/n]:"

**Given** l'utente ha risposto alle 4 domande
**When** lo script procede con l'inizializzazione
**Then** le operazioni vengono eseguite sequenzialmente dallo script bash:
**And** `git init` viene eseguito nella directory
**And** se BMAD richiesto: viene clonato/installato da GitHub con autoprovision
**And** se repo GitHub richiesto: `gh repo create` viene eseguito con il nome progetto
**And** ogni fase mostra progresso con messaggi chiari (stile splash screen)

**Given** l'utente risponde "n" alla domanda di inizializzazione
**When** lo script procede
**Then** BigIDE si avvia normalmente sulla cartella vuota
**And** nessuna operazione di provisioning viene eseguita

**Given** `gh` (GitHub CLI) non e installato e l'utente vuole creare un repo
**When** lo script tenta `gh repo create`
**Then** viene mostrato un messaggio: "GitHub CLI non trovato. Installa con: brew install gh"
**And** il resto dell'inizializzazione procede normalmente (git init, BMAD, ecc.)

**Given** la directory non e vuota (contiene file di progetto)
**When** BigIDE viene avviato
**Then** il rilevamento cartella vuota NON si attiva
**And** BigIDE si avvia normalmente senza prompt

**Given** il principio "script prima, AI dopo"
**When** l'inizializzazione e in corso
**Then** NESSUNA operazione coinvolge Claude Code o consuma token AI
**And** tutto il flusso e gestito da bash puro con `read`, `git`, `gh` e comandi standard
**And** Claude Code viene avviato nel pannello solo dopo che l'inizializzazione e completata

---

## Epic 9: Ambiente che Impara — Memoria Persistente

L'ambiente di sviluppo accumula conoscenza progetto per progetto, risolve errori già visti consultando la memoria e genera script di recovery riutilizzabili. L'IDE migliora con l'uso.

### Story 9.1: Integrazione claude-mem come Sistema di Memoria

As a Claude Code (agente AI),
I want salvare e consultare procedure risolutive in una memoria persistente,
So that possa risolvere problemi gia incontrati senza ripetere la diagnosi da zero.

**Acceptance Criteria:**

**Given** claude-mem e installato e configurato come plugin MCP di Claude Code
**When** Claude Code risolve un problema (es. errore di connessione DB, conflitto porte)
**Then** puo invocare il tool `save_memory` di claude-mem per salvare: descrizione problema, diagnosi, soluzione applicata
**And** la memoria viene persistita in SQLite + ChromaDB sotto `~/.claude-mem/`

**Given** Claude Code incontra un errore
**When** prima di diagnosticare, invoca `search` di claude-mem con la descrizione dell'errore
**Then** claude-mem restituisce memorie rilevanti tramite ricerca semantica (vector embeddings)
**And** se una soluzione precedente corrisponde, Claude Code puo applicarla direttamente

**Given** claude-mem e in esecuzione
**When** una sessione BigIDE crasha o viene chiusa improvvisamente
**Then** le memorie gia salvate NON vengono perse (NFR15)
**And** SQLite garantisce integrita dei dati anche in caso di interruzione

**Given** claude-mem usa il progressive disclosure 3-layer
**When** Claude Code cerca nella memoria
**Then** i risultati vengono restituiti in modo compatto (risparmio token ~10x)
**And** Claude Code puo richiedere dettagli aggiuntivi solo se necessario

**Given** claude-mem non e installato
**When** Claude Code tenta di usare i tool di memoria
**Then** i tool non sono disponibili ma Claude Code funziona normalmente
**And** nessun errore blocca il flusso di lavoro

### Story 9.2: Separazione Memoria Progetto e Generale

As a Claude Code (agente AI),
I want distinguere tra conoscenza specifica di un progetto e conoscenza generale,
So that le soluzioni universali siano disponibili ovunque e quelle specifiche restino nel contesto giusto.

**Acceptance Criteria:**

**Given** Claude Code salva una memoria
**When** il salvataggio avviene nel contesto di un progetto (es. `~/projects/my-app`)
**Then** la memoria viene taggata con il path del progetto
**And** il tag viene usato come filtro nelle ricerche successive

**Given** Claude Code cerca nella memoria dal progetto A
**When** la ricerca viene eseguita
**Then** i risultati includono: memorie specifiche del progetto A + memorie generali (senza tag progetto)
**And** le memorie di altri progetti (B, C) NON vengono incluse

**Given** Claude Code risolve un problema universale (es. "porta 3000 occupata → `lsof -ti :3000 | xargs kill`")
**When** salva la memoria
**Then** puo marcare la memoria come "generale" (senza tag progetto)
**And** la memoria sara disponibile in tutti i progetti

**Given** Claude Code cerca dalla directory di un nuovo progetto senza memorie specifiche
**When** la ricerca viene eseguita
**Then** vengono comunque restituite le memorie generali rilevanti
**And** l'agente ha accesso alla conoscenza accumulata da tutti i progetti

**Given** la separazione avviene tramite filtri su claude-mem as-is
**When** il filtro per project path viene applicato
**Then** nessun fork o modifica al codice di claude-mem e necessaria
**And** i filtri usano i campi metadata nativi di claude-mem

### Story 9.3: Generazione Script di Recovery Riutilizzabili

As a Claude Code (agente AI),
I want generare script di recovery eseguibili e salvarli in una cartella dedicata,
So that soluzioni ricorrenti diventino automatizzabili senza intervento AI e risparmino token.

**Acceptance Criteria:**

**Given** Claude Code risolve un problema con una procedura ripetibile
**When** identifica che la soluzione e scriptabile (es. sequenza di comandi shell)
**Then** genera uno script bash eseguibile con la soluzione
**And** lo salva in `~/.bigide/scripts/` con nome descrittivo (es. `fix-port-conflict.sh`)
**And** lo script include commenti che descrivono il problema e la soluzione

**Given** uno script viene generato
**When** viene salvato in `~/.bigide/scripts/`
**Then** lo script ha permessi di esecuzione (`chmod +x`)
**And** un riferimento allo script viene salvato in claude-mem con la descrizione del problema
**And** la prossima volta che il pattern si ripresenta, Claude Code puo eseguire lo script direttamente

**Given** un problema gia visto si ripresenta
**When** Claude Code trova lo script corrispondente in memoria
**Then** puo proporre di eseguire lo script invece di ri-diagnosticare il problema
**And** l'esecuzione dello script NON consuma token AI (principio "script prima, AI dopo")

**Given** lo script generato potrebbe non essere piu valido (es. percorsi cambiati)
**When** Claude Code esegue lo script e fallisce
**Then** ridiagnostica il problema, genera un nuovo script aggiornato
**And** lo script vecchio viene sostituito
**And** la memoria viene aggiornata con la nuova versione

**Given** l'utente vuole vedere gli script disponibili
**When** naviga in `~/.bigide/scripts/` (con Yazi o terminale)
**Then** gli script sono visibili con nomi leggibili
**And** ogni script contiene un header con descrizione, data di creazione e problema risolto

---

## Epic 10: Input Vocale

L'utente detta comandi con Whisper.cpp locale su Apple Silicon, zero costi token. Canale alternativo alla tastiera per accessibilita completa. Ultima priorita assoluta di implementazione.

### Story 10.1: Dittatura Vocale Locale con Whisper.cpp

As a sviluppatore con Parkinson,
I want dettare comandi e testo con la voce usando trascrizione locale,
So that possa interagire con l'IDE senza dipendere esclusivamente dalla tastiera e senza consumare token API.

**Acceptance Criteria:**

**Given** Whisper.cpp e installato e configurato su Apple Silicon
**When** l'utente attiva la dittatura vocale tramite keybinding dedicato (es. `prefix + v`)
**Then** il microfono inizia a catturare audio
**And** un indicatore visivo nella status bar segnala che la dittatura e attiva (es. icona microfono)

**Given** la dittatura vocale e attiva
**When** l'utente parla
**Then** Whisper.cpp trascrive l'audio in testo localmente su Apple Silicon
**And** la trascrizione avviene senza chiamate API esterne (zero token, zero costi)
**And** la latenza e accettabile per uso interattivo

**Given** il testo e stato trascritto
**When** la trascrizione e completata
**Then** il testo viene inserito nel pannello attualmente in focus
**And** se il pannello e Claude Code, il testo viene inviato come input
**And** se il pannello e il terminale, il testo viene inserito come comando

**Given** la dittatura vocale e attiva
**When** l'utente preme di nuovo il keybinding di toggle (es. `prefix + v`)
**Then** la dittatura si disattiva
**And** l'indicatore nella status bar scompare
**And** il microfono viene rilasciato

**Given** Whisper.cpp non e installato
**When** l'utente preme il keybinding per la dittatura
**Then** un messaggio viene mostrato: "Whisper.cpp non installato. Vedi documentazione per setup."
**And** nessun errore blocca l'IDE

**Given** il modello Whisper e caricato in memoria
**When** l'utente usa BigIDE normalmente (senza dittatura)
**Then** il modello NON consuma risorse se la dittatura non e attiva
**And** il caricamento del modello avviene solo all'attivazione della dittatura

**Given** l'ambiente e rumoroso o il microfono non funziona
**When** la trascrizione produce risultati vuoti o inaffidabili
**Then** il sistema gestisce gracefully senza inserire testo spazzatura
**And** l'utente puo annullare e riprovare
