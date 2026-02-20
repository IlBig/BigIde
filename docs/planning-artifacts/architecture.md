---
stepsCompleted: ['step-01-init', 'step-02-context', 'step-03-starter', 'step-04-decisions', 'step-05-patterns', 'step-06-structure', 'step-07-validation', 'step-08-complete']
status: 'complete'
completedAt: '2026-02-19'
inputDocuments: ['docs/planning-artifacts/prd.md', 'docs/planning-artifacts/prd-decisions-log.md', 'docs/tmux-mcp-ide-spec.md']
workflowType: 'architecture'
project_name: 'BigIDE'
user_name: 'Big'
date: '2026-02-19'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview

**Functional Requirements (48 FR in 10 aree):**

| Area | FR | Implicazione Architetturale |
|------|----|-----------------------------|
| Avvio e Sessione | FR1-FR5b (6) | Shell script come entry point, gestione stato sessione tmux, splash screen con progress feedback |
| Layout e Navigazione | FR6-FR10 (5) | Configurazione tmux declarativa, architettura layout estensibile, hook post-resize |
| Esplorazione File | FR11-FR15 (5) | Integrazione Yazi, custom previewer shell per qlmanage, LazyVim overlay |
| Agente AI + MCP | FR16-FR22 (7) | Server MCP TypeScript/stdio, ANSI stripping, wait-for-prompt polling, watch con diff |
| Browser Integration | FR23-FR25 (3) | AppleScript execution layer, stato sessione per scelta layout, Chrome come processo esterno |
| Git e Version Control | FR26-FR32 (7) | tmux key-table multi-livello, display-popup (tmux ≥ 3.3), gitmux config, mouse support su barra git |
| Monitoraggio e Status | FR33-FR35 (3) | tmux status-bar scripting, integrazione claude-monitor, intervalli refresh configurabili |
| Configurazione | FR36-FR38 (3) | Struttura `~/.bigide/` isolata, configurazioni dedicate per ogni tool, nessuna modifica a config globali |
| Installazione | FR39-FR42 (4) | Installer idempotente in shell, verifica dipendenze, repair MCP senza perdita sessione |
| Memoria e Autoapprendimento | FR43-FR46 (4) | Fork claude-mem, storage progetto vs generale, generazione script automatici |
| Input Vocale | FR47 (1) | Whisper.cpp locale, ultima priorità, integrazione futura con input pipeline |

**Non-Functional Requirements (19 NFR in 4 categorie):**

| Categoria | NFR | Vincolo Architetturale |
|-----------|-----|------------------------|
| Performance | NFR1-5 | MCP < 500ms, wait-for-prompt timeout 5s, keybinding < 100ms, splash screen con feedback |
| Accessibilità | NFR6-10 | ≥90% keyboard-only, keybinding sequenziali (no chord complessi), target click ampi, no drag & drop |
| Affidabilità | NFR11-15 | Sessione 1h+ stabile, isolamento fallimenti componenti, layout stabile in fullscreen, memoria crash-safe |
| Integrazione | NFR16-19 | MCP stdio senza config manuale, tmux ≥ 3.3, AppleScript macOS Ventura+, degradazione graceful |

### Scale & Complexity

- **Dominio primario**: CLI tool / system integration (non web, non API, non mobile)
- **Complessità**: media — nessun database, auth, o compliance, ma coordinazione multi-processo con IPC tramite tmux CLI
- **Componenti architetturali stimati**: ~6 (shell bootstrap, MCP server, tmux config, AppleScript layer, Yazi config/previewers, memory system)
- **Linguaggi coinvolti**: shell (bash/zsh), TypeScript, AppleScript
- **Runtime**: Node.js (MCP), Python (claude-monitor, perplexity-cli opzionale)

### Technical Constraints & Dependencies

| Vincolo | Impatto |
|---------|---------|
| **macOS only** (Apple Silicon) | AppleScript, brew, qlmanage — nessun supporto Linux/Windows nel MVP |
| **tmux ≥ 3.3** | Richiesto per `display-popup`, feature chiave per git actions e lazygit |
| **Ghostty** | Kitty graphics protocol per anteprime Yazi, fullscreen enforcement |
| **Node.js ≥ 18** | Runtime MCP server, installazione Claude Code |
| **Claude Max subscription** | Multi-istanza Claude Code (una per tab) consuma dall'abbonamento |
| **stdio transport** | MCP server deve essere un processo figlio di Claude Code, non un servizio standalone |
| **Isolamento `~/.bigide/`** | Ogni tool (tmux, Ghostty, Yazi, nvim) deve essere avviato con flag per config path dedicato |

### Cross-Cutting Concerns Identified

1. **Accessibilità keyboard-first**: permea ogni decisione di keybinding, navigazione, e interazione. Non è una feature — è un vincolo architetturale globale
2. **Isolamento configurazione**: ogni componente deve usare `~/.bigide/` senza toccare le config globali dell'utente. Richiede flag specifici per ogni tool
3. **Resilienza componenti**: il fallimento di un processo (MCP, Yazi, log viewer) non deve bloccare gli altri. L'architettura deve essere "fail-open" per ogni pannello
4. **Repair senza perdita di stato**: `bigide --repair` deve poter riavviare componenti singoli (es. MCP) senza distruggere la sessione tmux
5. **macOS integration layer**: AppleScript per Chrome positioning e Ghostty fullscreen è un concern trasversale che tocca bootstrap, MCP, e recovery

## Starter Template Evaluation

### Primary Technology Domain

**CLI tool / system integration** — BigIDE non è un'applicazione web/mobile. È un orchestratore di processi che coordina tool esistenti tramite tmux. Non esiste un singolo starter template; il progetto ha 3 fondazioni indipendenti.

### Starter Options Considered

#### MCP Server — `@modelcontextprotocol/create-server`

| Aspetto | Dettaglio |
|---------|-----------|
| SDK | `@modelcontextprotocol/sdk` **v1.26.0** |
| Roadmap | v2 stabile attesa Q1 2026 — v1.x raccomandata per produzione |
| Scaffold | `npx @modelcontextprotocol/create-server tmux-mcp` |
| Fornisce | Progetto TypeScript con entry point, server setup, tsconfig, package.json, build script |
| Dipendenze | `@modelcontextprotocol/sdk`, `typescript`, `zod` |

#### Shell Bootstrap — Bash puro vs Bashly

Bashly (framework YAML→bash, richiede Ruby) scartato: sovradimensionato per ~3 sotto-comandi, introduce dipendenza Ruby che contraddice "zero dipendenze al primo run". Scelto **bash puro con `set -euo pipefail`**.

#### Configurazioni Tool — Isolamento `~/.bigide/`

| Tool | Meccanismo Config Path | Supporto |
|------|----------------------|----------|
| tmux | `-f ~/.bigide/tmux/tmux.conf` | Flag nativo |
| Yazi | `YAZI_CONFIG_HOME=~/.bigide/yazi` | Env var dedicata |
| Ghostty | **Nessun flag `--config`** | Workaround: flag CLI inline |
| Neovim | `NVIM_APPNAME=bigide` o `-u` flag | Flag/env var |
| gitmux | `-cfg ~/.bigide/gitmux.conf` | Flag nativo |

**Decisione Ghostty**: Opzione C — BigIDE lancia Ghostty passando le opzioni chiave come flag CLI (`ghostty --font-family=... --background=...`). Nessun file config separato nel MVP.

### Memoria Persistente — claude-mem (as-is, senza fork)

| Aspetto | Dettaglio |
|---------|-----------|
| Repo | thedotmack/claude-mem |
| Storage | SQLite + ChromaDB (vector embeddings) |
| MCP Tools | 5 tool: search, timeline, get_observations, save_memory, __IMPORTANT |
| Retrieval | Progressive disclosure 3-layer (~10x token savings) |
| Worker | Express API su porta 37777 (Bun) |
| Licenza | AGPL-3.0 |
| Dipendenze | Node.js ≥ 18, Bun (auto-installed), uv/Python (ChromaDB) |

**Adeguatezza per BigIDE (~75% copertura):**

- Coperto: persistenza cross-sessione, ricerca semantica, MCP tools, cattura automatica, privacy controls
- Gap: nessuna separazione nativa progetto/generale (FR46) — risolvibile con filtri per project path senza fork
- Gap: script autogenerati (FR45) — feature separata, non responsabilità del sistema di memoria
- AGPL accettabile se BigIDE è open-source

**Strategia**: Usare claude-mem as-is in Phase 2. Separazione progetto/generale tramite filtri di ricerca. Script autogenerati come feature indipendente (Claude Code salva in `~/.bigide/scripts/` e registra riferimento in memoria).

### Selected Starters Summary

| Componente | Starter | Comando/Approccio |
|------------|---------|-------------------|
| MCP Server | `@modelcontextprotocol/create-server` | `npx @modelcontextprotocol/create-server tmux-mcp` |
| Shell bootstrap | Bash puro, strict mode | Struttura manuale, funzioni modulari |
| Configurazioni | File config manuali per tool | tmux.conf, gitmux.conf, Yazi config, nvim init.lua |
| Memoria | claude-mem (as-is, senza fork) | Plugin Claude Code, ChromaDB + SQLite |

### Architectural Decisions Established by Starters

- **Linguaggio MCP**: TypeScript con `@modelcontextprotocol/sdk` v1.26.0
- **Build MCP**: `tsc` → `dist/index.js`, distribuito come bundle compilato
- **Linguaggio bootstrap**: Bash puro con `set -euo pipefail`
- **Isolamento config**: env vars + flag CLI per tool, Ghostty via flag inline
- **Memoria**: claude-mem plugin, nessun fork, separazione logica per project path
- **Multi-linguaggio**: bash (bootstrap), TypeScript (MCP), Python (claude-monitor, ChromaDB), AppleScript (window management)
- **Node.js ≥ 18**: runtime condiviso MCP server + Claude Code

## Core Architectural Decisions

### Decision Priority Analysis

**Critical Decisions (bloccano implementazione):**
- Formato configurazione: JSON
- Architettura MCP server: specifica originale (file-per-tool, error codes strutturati, polling wait-for-prompt)
- Strategia layout: dichiarativo da subito (JSON)

**Important Decisions (formano l'architettura):**
- Distribuzione: clone+script MVP, curl one-liner pubblico, self-update
- Splash screen: ANSI puro, zero dipendenze
- Logging: file persistenti + stderr

**Deferred Decisions (post-MVP):**
- Profili layout per tipo progetto (Phase 3)
- Brew tap come canale distribuzione alternativo (Phase 3)
- Log rotation policy e retention (da definire in uso)

### Configurazione e Stato

| Decisione | Scelta | Rationale |
|-----------|--------|-----------|
| Formato config principale | **JSON** (`~/.bigide/config.json`) | Nativo in TypeScript (MCP server), leggibile con `jq` in bash. Unico formato per entrambi i consumatori |
| Stato sessione | **tmux nativo** | tmux gestisce sessioni, finestre, pannelli. Nessun state store aggiuntivo necessario |
| Preferenze browser layout | **Nel config.json** | Campo `browserLayout: "split" \| "fullscreen"`, salvato alla prima scelta della sessione |

### Architettura MCP Server

| Decisione | Scelta | Rationale |
|-----------|--------|-----------|
| Struttura tool | **File per tool** | `tools/capture.ts`, `tools/send.ts`, `tools/list.ts`, `tools/browser.ts` — come specifica originale |
| Error handling | **Error codes strutturati** | `{ error: { code: "PANE_NOT_FOUND", message: "..." } }` — diagnostica precisa per Claude Code |
| Wait-for-prompt | **Polling con capture-pane** | 100-200ms intervallo, pattern prompt configurabile, timeout 5s default |
| ANSI stripping | **Regex nel server** | Strip prima di restituire a Claude Code, utility in `utils/ansi.ts` |
| Logging | **File + stderr** | `~/.bigide/logs/mcp.log` per diagnostica, stderr per errori critici |

### Layout tmux — Strategia Dichiarativa

| Decisione | Scelta | Rationale |
|-----------|--------|-----------|
| Definizione layout | **File JSON dichiarativi** | `~/.bigide/layouts/default.json` — lo script bash interpreta con `jq` e genera comandi tmux |
| Estensibilità | **Un file JSON = un profilo** | Aggiungere layout = aggiungere file. Phase 3: profili per tipo progetto |
| Layout MVP | **`default.json`** | 6 pannelli: yazi (25%/70%), claude (75%/65%), monitor (15%/30%), log (35%/28%), terminal (50%/28%), git-bar (75%/2% = 1 riga). La git-bar è un pannello tmux dedicato di 1 riga sotto log/terminal, NON la tmux status-bar (che resta solo in alto: top bar con tab, CPU, RAM, ora) |

> **Nota**: Per monitor 27"+ (240+ colonne), un layout `expanded.json` aggiuntivo è previsto con pannelli extra (Chrome preview, Perplexity). La selezione avviene automaticamente in base a `tput cols` all'avvio.

### Distribuzione e Installazione

| Decisione | Scelta | Rationale |
|-----------|--------|-----------|
| MVP (uso personale) | **Clone repo + script setup** | `git clone` + `./setup.sh` — sufficiente per Big |
| Rilascio pubblico (Phase 3) | **curl one-liner da GitHub** | `curl -sSL https://raw.githubusercontent.com/.../install.sh \| bash` — zero prerequisiti |
| Aggiornamento | **Self-update** | `bigide --update` scarica nuova versione da GitHub releases, aggiorna script + MCP bundle |
| Idempotenza | **Verifica prima di installare** | Ogni dipendenza viene verificata (`command -v`) prima di installare. Riesecuzione sicura |

### Splash Screen e Progress Feedback

| Decisione | Scelta | Rationale |
|-----------|--------|-----------|
| Rendering | **ANSI puro** | Unicode progress bar (`▓▓▓░░░`), colori ANSI, `\r` per sovrascrittura. Zero dipendenze |
| Contenuto | **Fase per fase** | Logo ASCII BigIDE → checklist dipendenze → progress bar installazione → "Ready" |
| Applicabilità | **Avvio + installazione** | Splash screen sia al primo run (lungo) che agli avvii successivi (breve, solo logo + attach) |

### Logging e Diagnostica

| Decisione | Scelta | Rationale |
|-----------|--------|-----------|
| MCP server log | **`~/.bigide/logs/mcp.log`** | Timestamp, tool invocato, parametri, risultato. Persistente per diagnostica |
| MCP errori critici | **Anche su stderr** | Feedback immediato a Claude Code + persistenza su file |
| Bootstrap log | **`~/.bigide/logs/bigide.log`** | Ogni avvio, installazione, repair. Essenziale per `--repair` diagnostica |
| Rotazione | **Deferred** | Da definire in uso — inizialmente nessuna rotazione, file crescono |

### Decision Impact Analysis

**Sequenza di implementazione:**
1. Layout JSON dichiarativo (prerequisito per tutto il resto)
2. Script bash bootstrap con splash ANSI (entry point)
3. MCP server TypeScript (file-per-tool, 4 tool MVP)
4. Config JSON + logging
5. Installer idempotente con verifica dipendenze

**Dipendenze cross-componente:**
- Lo script bash deve leggere `config.json` (→ `jq` come dipendenza)
- Lo script bash deve leggere `layouts/default.json` (→ stesso `jq`)
- Il MCP server scrive in `~/.bigide/logs/mcp.log` (→ directory creata dal bootstrap)
- Il repair (`--repair`) deve conoscere il PID del MCP server (→ PID file in `~/.bigide/mcp.pid` o query tmux)

## Implementation Patterns & Consistency Rules

### Conflict Points Identified

BigIDE ha 3 linguaggi (bash, TypeScript, AppleScript) e ~8 file di configurazione. Gli agenti AI potrebbero fare scelte incompatibili su naming, struttura, error handling e comunicazione tra componenti.

### Naming Patterns

| Contesto | Convenzione | Esempio |
|----------|-------------|---------|
| **Bash** — funzioni | `snake_case` | `create_layout()`, `check_dependency()`, `show_splash()` |
| **Bash** — variabili | `UPPER_SNAKE` costanti, `lower_snake` locali | `BIGIDE_HOME`, `pane_id` |
| **Bash** — file script | `kebab-case` | `bigide`, `setup-layout.sh`, `check-deps.sh` |
| **TypeScript** — funzioni/metodi | `camelCase` | `capturePane()`, `sendKeys()`, `stripAnsi()` |
| **TypeScript** — classi/tipi | `PascalCase` | `TmuxClient`, `PaneInfo`, `McpError` |
| **TypeScript** — file | `kebab-case` | `capture.ts`, `tmux-client.ts`, `ansi-strip.ts` |
| **TypeScript** — costanti | `UPPER_SNAKE` | `DEFAULT_TIMEOUT`, `MAX_CAPTURE_LINES` |
| **JSON config** — chiavi | `camelCase` | `browserLayout`, `statusInterval`, `logLevel` |
| **JSON layout** — chiavi | `camelCase` | `paneName`, `splitDirection`, `sizePercent` |
| **tmux** — sessioni | `bigide-{directory}` | `bigide-my-project` |
| **tmux** — finestre (tab) | Nome directory progetto | `my-project` |
| **tmux** — pannelli (id logico) | `lower_snake` | `yazi`, `claude`, `monitor`, `log`, `terminal`, `git_bar` |
| **Log messages** | `[LEVEL] [component] message` | `[ERROR] [mcp] PANE_NOT_FOUND: target %3` |

**Anti-pattern**: mischiare `camelCase` e `snake_case` nello stesso contesto. TypeScript tutto `camelCase`, bash tutto `snake_case`. I config JSON seguono TypeScript (`camelCase`).

### Structure Patterns

**Struttura repository BigIDE:**

```
bigide/
├── bin/
│   └── bigide                    # Entry point bash (in PATH)
├── src/
│   ├── shell/
│   │   ├── lib/                  # Funzioni bash modulari (sourced)
│   │   │   ├── deps.sh           # Verifica/installazione dipendenze
│   │   │   ├── layout.sh         # Parsing JSON layout → comandi tmux
│   │   │   ├── splash.sh         # Splash screen ANSI
│   │   │   └── repair.sh         # Logica --repair
│   │   └── applescript/          # Script AppleScript
│   │       ├── chrome-split.scpt
│   │       └── ghostty-fullscreen.scpt
│   └── mcp/
│       ├── src/                  # Sorgente TypeScript MCP server
│       │   ├── index.ts
│       │   ├── server.ts
│       │   ├── tools/
│       │   ├── tmux/
│       │   ├── utils/
│       │   └── config.ts
│       ├── package.json
│       └── tsconfig.json
├── config/
│   ├── default-layout.json       # Layout MVP
│   ├── tmux.conf                 # Config tmux BigIDE
│   ├── gitmux.conf               # Config gitmux
│   └── yazi/                     # Config Yazi
│       └── yazi.toml
├── tests/
│   ├── mcp/                     # Test MCP server
│   │   ├── capture.test.ts
│   │   ├── send.test.ts
│   │   └── list.test.ts
│   └── shell/                   # Test bash (bats)
│       ├── deps.bats
│       └── layout.bats
├── docs/                         # Documentazione progetto (BMAD artifacts)
├── setup.sh                      # Script setup MVP
└── README.md
```

**Regole:**
- Test co-located per dominio: `tests/mcp/` specchia `src/mcp/src/tools/`, `tests/shell/` specchia `src/shell/lib/`
- Config separata dai sorgenti: `config/` contiene i file copiati in `~/.bigide/` dall'installer
- Shell modulare: `bin/bigide` è snello, sourca le funzioni da `src/shell/lib/`
- MCP server autocontenuto: `src/mcp/` è un progetto Node.js indipendente con il proprio `package.json`

### Error Handling Patterns

**Bash:**
```bash
set -euo pipefail
# Funzioni ritornano 0/1, non exit
check_dependency() { command -v "$1" &>/dev/null; }
# Trap per cleanup
trap cleanup EXIT
# Messaggi: die() = errore fatale, warn() = warning, info() = successo
die() { echo -e "\033[31m[ERROR]\033[0m $*" >&2; exit 1; }
warn() { echo -e "\033[33m[WARN]\033[0m $*" >&2; }
info() { echo -e "\033[32m[OK]\033[0m $*"; }
```

**TypeScript (MCP server):**
```typescript
type ErrorCode =
  | "PANE_NOT_FOUND"
  | "SESSION_NOT_FOUND"
  | "COMMAND_TIMEOUT"
  | "TMUX_ERROR"
  | "APPLESCRIPT_ERROR"
  | "INVALID_PARAMS";
// Ogni tool wrappa in try/catch, restituisce errore strutturato
// MAI throw non gestito — il server MCP non deve crashare
```

**AppleScript:** ogni script con `try / on error` — log errore, return graceful.

**Regola universale**: nessun componente deve crashare per un errore gestibile. Fail-open: logga e continua. Solo `die()` in bash per errori irrecuperabili.

### Communication Patterns

| Da → A | Meccanismo | Regola |
|--------|------------|--------|
| Bash → tmux | `tmux` CLI | Comandi diretti: `tmux split-window`, `tmux send-keys` |
| MCP → tmux | `child_process.execSync` | **Solo via wrapper** `tmux/client.ts`, mai chiamate tmux dirette nei tool |
| MCP → AppleScript | `osascript -e` | **Solo via wrapper** `utils/applescript.ts` |
| Bash → MCP | Nessuna | MCP è processo figlio di Claude Code, non del bash script |
| Claude Code → MCP | stdio (JSON-RPC) | Gestito dall'SDK, nessun codice custom |
| Bash → config | `jq` per JSON | Sempre `jq -r '.key'`, mai parsing manuale |

**Regola chiave**: ogni componente comunica con tmux attraverso un solo wrapper. In TypeScript: `TmuxClient`. In bash: funzioni in `lib/layout.sh`. Mai comandi tmux sparsi.

### Config JSON Schema & Defaults

```json
{
  "version": 1,
  "browserLayout": "split",
  "claudePlan": "max5",
  "theme": "tokyonight-night",
  "statusInterval": 15,
  "mcp": {
    "waitForPromptTimeout": 5000,
    "captureDefaultLines": 50,
    "logLevel": "info"
  },
  "ghostty": {
    "fontFamily": "JetBrainsMono Nerd Font",
    "fontSize": 13,
    "background": "1e1e2e"
  }
}
```

- Ogni campo ha un default — config.json è opzionale, mai obbligatorio per l'avvio
- Schema versioned (`"version": 1`) per migrazioni future
- MCP server e bash script leggono lo stesso file — single source of truth

### Enforcement Guidelines

**Ogni agente AI che implementa codice per BigIDE DEVE:**

1. Usare le naming conventions del linguaggio corrente (bash=snake, TS=camel, JSON=camel)
2. Non comunicare con tmux direttamente — usare il wrapper (`TmuxClient` o funzioni `lib/`)
3. Non crashare per errori gestibili — fail-open, logga, continua
4. Non modificare config globali dell'utente — solo `~/.bigide/`
5. Non introdurre dipendenze non nel manifest delle dipendenze
6. Scrivere test per ogni tool MCP e ogni funzione bash critica
7. Loggare con il formato `[LEVEL] [component] message`

### Which-Key Banner

Il which-key banner è implementato come `tmux display-popup` attivato dopo un timeout di 500ms dal prefix. Se l'utente preme un keybinding entro 500ms, il popup non appare. Se il timeout scade senza input, il popup mostra i keybinding disponibili nel contesto corrente.

## Project Structure & Boundaries

### Requirements to Structure Mapping

| Area FR | Componente | Directory Repo | Directory Runtime |
|---------|------------|----------------|-------------------|
| FR1-FR5b (Avvio/Sessione) | Shell bootstrap | `bin/bigide`, `src/shell/lib/` | — |
| FR5b (Splash screen) | Splash ANSI | `src/shell/lib/splash.sh` | — |
| FR6-FR10 (Layout/Navigazione) | Layout engine + tmux | `src/shell/lib/layout.sh`, `config/layouts/` | `~/.bigide/layouts/` |
| FR11-FR15 (Esplorazione file) | Yazi config + previewers | `config/yazi/` | `~/.bigide/yazi/` |
| FR16-FR22 (MCP) | MCP server | `src/mcp/` | `~/.bigide/mcp/tmux-mcp/dist/` |
| FR23-FR25 (Browser) | AppleScript + MCP tool | `src/shell/applescript/`, `src/mcp/src/tools/browser.ts` | — |
| FR26-FR32 (Git) | tmux key-table config | `config/tmux.conf` | `~/.bigide/tmux/tmux.conf` |
| FR33-FR35 (Status bar) | tmux status + script | `config/tmux.conf`, `src/shell/lib/status.sh` | `~/.bigide/tmux/tmux.conf` |
| FR36-FR38 (Configurazione) | Config schema + installer | `config/default-config.json`, `setup.sh` | `~/.bigide/config.json` |
| FR39-FR42 (Installazione) | Installer idempotente | `setup.sh`, `src/shell/lib/deps.sh` | — |
| FR43-FR46 (Memoria) | claude-mem (esterno) | — (plugin Claude Code) | `~/.bigide/memory/` (gestito da claude-mem) |
| FR47 (Voce) | Whisper.cpp (futuro) | — | — |

### Complete Project Directory Structure

```
bigide/
├── bin/
│   └── bigide                          # Entry point bash — in PATH dopo setup
│
├── src/
│   ├── shell/
│   │   ├── lib/
│   │   │   ├── common.sh              # Funzioni condivise: die(), warn(), info(), log()
│   │   │   ├── deps.sh                # Verifica e installazione dipendenze (brew, tools)
│   │   │   ├── layout.sh              # Parser JSON layout → comandi tmux
│   │   │   ├── splash.sh              # Splash screen ANSI + progress bar
│   │   │   ├── session.sh             # Gestione sessione tmux (create, attach, detect)
│   │   │   ├── repair.sh              # Logica --repair (restart MCP, health check)
│   │   │   ├── update.sh              # Logica --update (self-update da GitHub)
│   │   │   ├── status.sh              # Script per status bar (CPU, RAM)
│   │   │   └── config-reader.sh       # Lettura config.json via jq con defaults
│   │   └── applescript/
│   │       ├── chrome-split.scpt       # Layout Chrome 50/50
│   │       ├── chrome-fullscreen.scpt  # Chrome fullscreen separato
│   │       └── ghostty-fullscreen.scpt # Forza Ghostty fullscreen
│   │
│   └── mcp/
│       ├── src/
│       │   ├── index.ts                # Entry point — setup server MCP
│       │   ├── server.ts               # Registrazione tool, lifecycle
│       │   ├── tools/
│       │   │   ├── capture.ts          # tmux_capture_pane
│       │   │   ├── send.ts             # tmux_send_keys (+ wait-for-prompt)
│       │   │   ├── list.ts             # tmux_list_panes / list_sessions / list_windows
│       │   │   ├── browser.ts          # open_browser (AppleScript)
│       │   │   ├── manage.ts           # create/close/resize pane (Phase 2)
│       │   │   └── watch.ts            # tmux_watch_pane con diff (Phase 2)
│       │   ├── tmux/
│       │   │   ├── client.ts           # Wrapper unico per tmux CLI
│       │   │   ├── parser.ts           # Parsing output tmux (list-panes, etc.)
│       │   │   └── types.ts            # Tipi: PaneInfo, SessionInfo, WindowInfo
│       │   ├── utils/
│       │   │   ├── ansi.ts             # Stripping codici ANSI
│       │   │   ├── applescript.ts      # Wrapper esecuzione AppleScript
│       │   │   ├── logger.ts           # Logger su file + stderr
│       │   │   └── errors.ts           # ErrorCode type + factory
│       │   └── config.ts               # Lettura ~/.bigide/config.json, defaults
│       ├── package.json
│       ├── tsconfig.json
│       └── .npmrc
│
├── config/
│   ├── layouts/
│   │   └── default.json               # Layout MVP: 6 pannelli con proporzioni
│   ├── default-config.json             # Config di default (copiato in ~/.bigide/)
│   ├── tmux.conf                       # Config tmux BigIDE completa
│   ├── gitmux.conf                     # Config gitmux per git bar
│   └── yazi/
│       ├── yazi.toml                   # Config Yazi
│       ├── keymap.toml                 # Keymap Yazi custom
│       └── plugins/
│           └── ql-preview.sh           # Custom previewer Quick Look macOS
│
├── tests/
│   ├── mcp/
│   │   ├── capture.test.ts             # Test capture_pane
│   │   ├── send.test.ts                # Test send_keys + wait-for-prompt
│   │   ├── list.test.ts                # Test list_panes/sessions/windows
│   │   ├── browser.test.ts             # Test open_browser
│   │   ├── tmux-client.test.ts         # Test wrapper TmuxClient
│   │   └── ansi.test.ts                # Test ANSI stripping
│   └── shell/
│       ├── deps.bats                   # Test verifica dipendenze
│       ├── layout.bats                 # Test parser layout JSON
│       └── session.bats                # Test gestione sessione
│
├── docs/
│   ├── planning-artifacts/             # PRD, architecture, epics (BMAD)
│   └── tmux-mcp-ide-spec.md           # Specifica originale
│
├── setup.sh                            # Script setup MVP (clone → installazione)
├── .gitignore
└── README.md
```

### Runtime Structure — `~/.bigide/`

```
~/.bigide/
├── config.json                 # Configurazione utente (da default-config.json)
├── layouts/
│   └── default.json            # Layout attivo (da config/layouts/)
├── tmux/
│   └── tmux.conf               # Config tmux (da config/tmux.conf)
├── ghostty/                    # (Riservato per future config Ghostty)
├── yazi/
│   ├── yazi.toml
│   ├── keymap.toml
│   └── plugins/
│       └── ql-preview.sh
├── nvim/
│   └── init.lua                # Config LazyVim per overlay
├── mcp/
│   └── tmux-mcp/
│       └── dist/
│           └── index.js        # MCP server compilato
├── scripts/                    # Script autogenerati da Claude Code (Phase 2)
├── memory/                     # Gestito da claude-mem (Phase 2)
├── logs/
│   ├── mcp.log
│   └── bigide.log
└── gitmux.conf
```

### Architectural Boundaries

**Confini chiave:**

| Confine | Regola |
|---------|--------|
| **bash ↔ tmux** | Lo script bash crea sessione e pannelli all'avvio. Dopo, non interagisce più con tmux (tranne `--repair`) |
| **MCP ↔ tmux** | Solo via `TmuxClient` (`tmux/client.ts`). Mai comandi tmux diretti nei tool |
| **MCP ↔ macOS** | Solo via `utils/applescript.ts`. Mai `osascript` diretti nei tool |
| **Claude Code ↔ MCP** | Solo via stdio JSON-RPC. Nessun side-channel |
| **Repo ↔ Runtime** | `config/` = sorgente. `~/.bigide/` = runtime. L'installer copia, l'utente modifica solo runtime |
| **Bash ↔ config** | Solo via `jq`. Mai parsing manuale di JSON |

### Data Flow

**Avvio:**
```
bin/bigide → splash.sh → deps.sh → config-reader.sh → layout.sh → tmux (sessione)
                                                                       ↓
                                                              pannelli attivi
                                                              Claude Code → MCP server (stdio)
```

**Operazione MCP (es. capture_pane):**
```
Claude Code → [stdio JSON-RPC] → MCP server → tools/capture.ts
                                                    ↓
                                              TmuxClient.capturePane()
                                                    ↓
                                              child_process.execSync("tmux capture-pane ...")
                                                    ↓
                                              ansi.stripAnsi(output)
                                                    ↓
                                              → [stdio JSON-RPC] → Claude Code
```

**Repair:**
```
bin/bigide --repair → repair.sh → trova PID MCP → kill → rilancia MCP → health check → log
```

### Integration Points — External Tools

| Tool Esterno | Punto di Integrazione | Configurazione |
|--------------|-----------------------|----------------|
| tmux | CLI (`tmux` command) | `~/.bigide/tmux/tmux.conf` via `-f` flag |
| Ghostty | CLI flags all'avvio | Flag inline (`--font-family`, `--background`) |
| Yazi | Processo nel pannello | `YAZI_CONFIG_HOME=~/.bigide/yazi` |
| Neovim/LazyVim | Overlay da Yazi | `NVIM_APPNAME=bigide` o `-u ~/.bigide/nvim/init.lua` |
| gitmux | Widget tmux status | `-cfg ~/.bigide/gitmux.conf` |
| Claude Code | Processo nel pannello | MCP server registrato in `~/.claude/settings.json` |
| claude-monitor | Processo nel pannello | `--plan max5 --theme dark --refresh-rate 10` |
| Chrome | Processo esterno macOS | AppleScript per positioning |
| claude-mem | Plugin Claude Code | `~/.claude-mem/` (Phase 2, config separata) |

## Architecture Validation Results

### Coherence Validation ✅

**Decision Compatibility:** Tutte le decisioni tecnologiche sono compatibili. JSON come formato config unico serve sia bash (via `jq`) che TypeScript (nativo). Layout dichiarativo JSON usa lo stesso meccanismo. Multi-meccanismo isolamento config (tmux `-f`, Yazi env var, Ghostty flags CLI, nvim env var) raggiunge lo stesso obiettivo con il tool nativo di ogni componente.

**Pattern Consistency:** Naming conventions non si sovrappongono (bash=snake, TS=camel, JSON=camel). Error handling è coerente (fail-open ovunque). Communication patterns passano tutti per wrapper dedicati.

**Structure Alignment:** Separazione repo/runtime (`config/` → `~/.bigide/`) è rispettata in ogni componente. MCP server autocontenuto. Shell modulare con sourcing.

### Requirements Coverage ✅

**Functional Requirements:** 48/48 FR coperti architetturalmente. FR21-FR22 (MCP avanzato) e FR43-FR47 (memoria, voce) sono in fasi successive con struttura predisposta.

**Non-Functional Requirements:** 19/19 NFR hanno supporto architetturale. NFR7 (one-hand keybinding) richiede scelta attenta del prefix tmux — raccomandato `Ctrl+Space` o `Ctrl+A`.

### Gap Analysis

**Gap 1 — FR32 (Git mouse su barra status):** Le status bar tmux non sono cliccabili. FR32 va inteso come mouse support nei popup git interattivi (lazygit, fzf) e nel file browser Yazi. La barra git resta informativa. Nessun cambiamento architetturale — chiarimento nel PRD.

**Gap 2 — NFR7 (Prefix ergonomico):** Il prefix tmux deve essere scelto per accessibilità one-hand. Configurabile in `tmux.conf`, raccomandato `Ctrl+Space`. Decisione finale durante implementazione config tmux.

**Gap 3 — MCP Repair:** Il server MCP è processo figlio di Claude Code (stdio). `--repair` riavvia Claude Code nel pannello (send-keys `exit` + rilancio), che riavvia automaticamente il MCP server. Dettaglio implementativo gestito da `repair.sh`.

### Architecture Completeness Checklist

**✅ Requirements Analysis**
- [x] Project context analizzato (48 FR, 19 NFR)
- [x] Scale e complessità valutate (media, CLI/system integration)
- [x] Vincoli tecnici identificati (macOS, tmux ≥ 3.3, Node.js ≥ 18)
- [x] Cross-cutting concerns mappati (accessibilità, isolamento, resilienza)

**✅ Architectural Decisions**
- [x] Configurazione: JSON con jq
- [x] MCP server: TypeScript, file-per-tool, error codes strutturati
- [x] Layout: dichiarativo JSON
- [x] Distribuzione: clone MVP, curl pubblico, self-update
- [x] Splash: ANSI puro
- [x] Logging: file + stderr
- [x] Memoria: claude-mem as-is

**✅ Starter Templates**
- [x] MCP: @modelcontextprotocol/create-server v1.26.0
- [x] Shell: bash puro strict mode
- [x] Config: file manuali per tool
- [x] Ghostty: flag CLI inline

**✅ Implementation Patterns**
- [x] Naming conventions per linguaggio
- [x] Error handling cross-linguaggio (fail-open)
- [x] Communication patterns con wrapper
- [x] Config JSON schema con defaults
- [x] Enforcement guidelines (7 regole)

**✅ Project Structure**
- [x] Struttura repo completa con tutti i file
- [x] Struttura runtime ~/.bigide/ definita
- [x] FR → directory mapping completo
- [x] Confini architetturali definiti
- [x] Flussi dati documentati

### Architecture Readiness Assessment

**Stato: READY FOR IMPLEMENTATION**

**Confidence Level: Alta**

**Punti di forza:**
- Separazione netta repo/runtime (config/ → ~/.bigide/)
- Wrapper pattern per tmux e AppleScript previene conflitti tra agenti
- Layout dichiarativo abilita estensibilità senza refactoring
- Error handling coerente cross-linguaggio
- Single source of truth per configurazione

**Aree per enhancement futuro:**
- Prefix tmux ergonomico (NFR7) — da definire in implementazione
- Meccanismo preciso MCP repair — dettaglio implementativo in repair.sh
- Chiarimento FR32 su limiti mouse tmux status bar
- Log rotation quando i file crescono

### Implementation Handoff

**Ogni agente AI deve:**
1. Seguire tutte le decisioni architetturali esattamente come documentate
2. Usare i pattern di implementazione in modo coerente
3. Rispettare la struttura progetto e i confini
4. Consultare questo documento per ogni domanda architetturale

**Prima priorità di implementazione:**
1. `npx @modelcontextprotocol/create-server tmux-mcp` — scaffold MCP server
2. `config/layouts/default.json` — definire il layout MVP
3. `bin/bigide` + `src/shell/lib/` — script bootstrap con splash
