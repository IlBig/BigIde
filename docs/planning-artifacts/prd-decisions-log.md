# BigIDE — Registro Decisioni PRD

**Data**: 2026-02-19
**Partecipanti**: Big (Product Owner) + BMAD Master (Facilitatore)
**Documento di input**: `docs/tmux-mcp-ide-spec.md`

Questo file documenta ogni decisione presa durante la creazione collaborativa del PRD, step per step. Serve come riferimento per le fasi successive (architettura, epic, implementazione) per comprendere il *perché* dietro ogni scelta.

---

## Step 1 — Inizializzazione

- **Input document identificato**: `docs/tmux-mcp-ide-spec.md` (742 righe) — specifica tecnica dettagliata del progetto tmux-mcp IDE
- **Template PRD**: creato da template BMAD standard in `docs/planning-artifacts/prd.md`

---

## Step 2 — Discovery & Classification

| Decisione | Valore | Motivazione |
|-----------|--------|-------------|
| **Tipo progetto** | `cli_tool/developer_tool` (ibrido) | BigIDE è sia un comando CLI (`bigide`) che un ambiente di sviluppo completo |
| **Dominio** | `general` | Strumento di sviluppo software, nessun dominio verticale specifico |
| **Complessità** | `low-medium` | Nessuna compliance, ma integrazione multi-tool non banale |
| **Contesto** | `greenfield` | Nessun codice esistente, progetto da zero |

---

## Step 2b — Deep Vision Discovery

### Decisioni fondamentali emerse dalla visione di Big

1. **Flow state come obiettivo primario**: Big descrive il flow state come il momento in cui "tutto funziona con la tastiera — navigare file, anteprima, editing, chiedere a Claude Code, browser che si apre da solo". Questo guida ogni decisione di UX.

2. **Parkinson come driver di design**: Big convive con il Parkinson. Il mouse è nemico. Ogni interazione deve essere possibile da tastiera o dittatura vocale. Questa non è una feature — è il principio architetturale fondamentale.

3. **Claude Code come abilitatore**: Big è tornato a programmare grazie a Claude Code. BigIDE è l'ambiente costruito attorno a questa capacità ritrovata. L'AI non è un'aggiunta — è il motivo per cui il progetto esiste.

4. **Dittatura vocale**: Whisper.cpp locale su Apple Silicon, zero costi token. Big la vuole come canale di input alternativo alla tastiera.

5. **Pubblico vs personale**: Inizialmente per uso personale di Big. A medio termine: rilascio pubblico su GitHub come dimostrazione di cosa l'AI può abilitare per sviluppatori con disabilità.

6. **Estetica conta**: "Non basta che funzioni — deve essere bello da usare." Tema curato, layout elegante, status bar informative.

---

## Step 3 — Success Criteria

### Decisioni su priorità

| Decisione | Dettaglio |
|-----------|-----------|
| **Dittatura vocale**: priorità alta post-MVP | Big: "Dettatura integrata zero costi token sarebbe eccezionale da tenere presente appena possibile dopo il prototipo" — spostata come prima feature di Phase 2 |
| **Metrica keyboard-first** | ≥90% operazioni eseguibili da tastiera (non 100%, il mouse è accettabile in situazioni limitate) |
| **Sessione senza frizione** | 1+ ora senza dover uscire dall'IDE come benchmark |
| **Setup < 5 minuti** | Da cartella vuota a progetto funzionante |

---

## Step 4 — User Journeys

### Decisioni per journey

| Journey | Decisione di Big | Impatto |
|---------|------------------|---------|
| **Journey 3 (Agente che Impara)** | Deve includere sistema di memoria persistente basato su fork di claude-mem. Tre livelli: memoria progetto, memoria generale, script autogenerati | Aggiunto FR43-FR46, struttura `~/.bigide/memory/` |
| **Journey 3** | L'agente deve avere autoapprendimento: ogni errore risolto diventa conoscenza permanente, genera script di recovery riutilizzabili | Pattern di autoapprendimento nella sezione Innovation |
| **Journey 4 (Edge Case)** | Ghostty deve essere forzato in fullscreen quando BigIDE è attivo | FR4 aggiornato, elimina alla radice il problema resize pannelli |

---

## Step 5 — Domain (Skipped)

- **Decisione**: Step saltato — dominio `general`, complessità bassa, nessun requisito di dominio specifico necessario

---

## Step 6 — Innovation

### 4 aree di innovazione identificate

1. **AI-Orchestrated Terminal IDE** — paradigma nuovo, nessun concorrente diretto
2. **Agente con memoria persistente e autoapprendimento** — ispirato a claude-mem
3. **Accessibility-first by design** — progettato dal giorno zero per Parkinson
4. **Natural language come interfaccia di comando** — l'utente descrive l'intento, l'agente orchestra tutto

---

## Step 7 — CLI & Developer Tool Requirements

### Decisioni chiave

| Decisione | Dettaglio | Motivazione di Big |
|-----------|-----------|-------------------|
| **Comando unico `bigide`** | Un solo eseguibile per installazione, lancio e gestione | "Il comando bigide installa tutto automaticamente. Un comando e via" |
| **Configurazione isolata in `~/.bigide/`** | Tutte le config (tmux, ghostty, yazi, nvim, mcp, memory) in cartella dedicata | "Non voglio toccare le configurazioni globali dell'utente" |
| **Nuovo tab dall'interno** | Keybinding dedicato per aprire nuovo progetto in nuovo tab tmux | Big vuole poter lavorare su più progetti senza uscire dall'IDE |
| **Shell completion** | Non prioritario per ora — il terminale è *dentro* l'IDE | Chiarimento: la shell completion sarebbe per il terminale esterno, non per quello interno |
| **Documentazione** | Dopo che il prodotto è fatto, non durante | "La documentazione la facciamo dopo" |

### Installation flow deciso

1. Verifica dipendenze → 2. brew se assente → 3. brew install (Ghostty, tmux, Node.js, Neovim, Yazi, gitmux, lazygit, fzf, ffmpegthumbnailer, ImageMagick) → 4. npm install Claude Code → 5. uv install claude-monitor → 6. perplexity-cli → 7. struttura `~/.bigide/` → 8. registra MCP server → 9. primo lancio

---

## Step 8 — Scoping & Phase Calibration

### Decisione critica: MCP nel MVP

| Prima | Dopo | Motivazione |
|-------|------|-------------|
| MCP in Phase 2 (Growth) | **MCP base in Phase 1 (MVP)** | Senza MCP, Claude Code non ha occhi né mani. Il differenziatore del prodotto non esiste. Big: "concordo" |

### MCP MVP scope

Solo 4 tool base nel MVP (non 12+):
- `capture_pane` — leggere contenuto pannelli
- `send_keys` — inviare comandi ai pannelli
- `list_panes` — elencare pannelli con info
- `open_browser` — aprire Chrome con layout automatico

Tool avanzati (`watch_pane`, `create_pane`, `close_pane`, `resize_pane`) rimandati a Phase 2.

### Installer split

| Phase 1 (MVP) | Phase 2 (Growth) |
|----------------|------------------|
| Setup script guidato (manuale ma assistito) | `bigide` installer completo e idempotente, un comando installa tutto su Mac pulito |

Big ha confermato: setup manuale accettabile per uso personale nel MVP.

---

## Step 9 — Functional Requirements

### Decisioni su FR specifici

| FR | Decisione di Big | Cambiamento |
|----|-------------------|-------------|
| **FR6 (Layout)** | "Verranno aggiunti altri pannelli e altre disposizioni" | Layout con architettura estensibile, non proporzioni fisse |
| **FR7 (Navigazione)** | "Preferisco si usi prefix + freccia direzionale" | Cambiato da vim-style (prefix+h/j/k/l) a prefix + frecce direzionali |
| **FR32 (Git mouse)** | "Mi dispiacerebbe poter gestire questo pannello anche tramite mouse" | Aggiunto FR32: interazione mouse sulla barra git e popup |
| **FR47 (Voice input)** | "Ultima cosa in assoluto da implementare" | Dittatura vocale come ultima priorità assoluta |

### Scope keybinding navigazione

- `prefix + frecce direzionali` — navigazione direzionale tra pannelli
- `prefix + 1-5` — salto diretto a pannello specifico
- `prefix + z` — zoom/unzoom pannello
- `prefix + g` + sottotasto — operazioni git

---

## Step 10 — Non-Functional Requirements

### Decisione su NFR4 (Startup)

| Prima | Dopo | Motivazione di Big |
|-------|------|-------------------|
| "Avvio IDE < 10 secondi" | **Tempo di avvio ininfluente, splash screen con progress bar** | "Il tempo di avvio è ininfluente... piuttosto mettiamo una splashscreen e progress bar così l'utente sa cosa sta facendo" |

Questo ha generato anche **FR5b**: splash screen con progress bar durante avvio e installazione.

---

## Step 11 — Polish

### Correzioni applicate durante lucidatura finale

| Problema | Correzione |
|----------|------------|
| **Naming inconsistency**: "tmux-mcp IDE", "tmux-ide", "BigIDE" mischiati | Unificato tutto a "BigIDE" (prodotto) e "bigide" (comando) |
| **Keybinding inconsistency**: vim-style menzionato nello scope | Corretto ovunque a "prefix + frecce direzionali" |
| **Sezioni duplicate**: "Product Scope" e "Project Scoping & Phased Development" separate | Consolidato in unica sezione "Product Scope & Phased Development" |
| **Risk mitigation duplicata**: presente in due punti diversi | Consolidata sotto Product Scope |
| **Ordine sezioni**: non ottimale per lettore | Riordinato: Executive → Classification → Success → Scope → Journeys → Innovation → CLI Requirements → FR → NFR |

---

## Riepilogo Priorità Decise

### Phase 1 — MVP (priorità massima)
1. Layout tmux + tema + Ghostty fullscreen
2. Splash screen + progress bar
3. Status bar (superiore + inferiore gitmux)
4. Yazi file browser
5. Claude Code pannello principale
6. **MCP server base** (4 tool)
7. Browser Chrome integration
8. Script bootstrap `bigide`
9. Keybinding navigazione (prefix + frecce)
10. Setup script guidato

### Phase 2 — Growth (in ordine di priorità)
1. **Dittatura vocale** (Whisper.cpp) — prima feature dopo MVP
2. **Installer completo** `bigide` idempotente
3. Auto-provisioning cartella vuota
4. Keybinding git completi
5. **Memoria persistente** (fork claude-mem)
6. Script autogenerati
7. Pannello claude-monitor
8. MCP avanzato (watch, create, close, resize pane)

### Phase 3 — Vision
1. Toggle Perplexity
2. LazyVim overlay da Yazi
3. Profili layout
4. `bigide --update`
5. Rilascio pubblico GitHub
6. Community

### Ultima priorità assoluta
- **FR47**: Dittatura vocale (spostata da Big come "ultima cosa in assoluto")

*Nota: c'è una tensione tra "dittatura vocale prima feature di Phase 2" (Step 3) e "ultima cosa in assoluto" (Step 9). La decisione finale di Big in Step 9 prevale: la dittatura vocale resta in Phase 2 come feature elencata, ma va implementata per ultima.*

---

## Decisioni di Design Implicite (da portare in Architettura)

Queste decisioni sono emerse durante il PRD ma avranno impatto diretto sull'architettura:

1. **Script `bigide` in shell (bash/zsh)** — zero dipendenze al primo run
2. **MCP server in TypeScript** — usa `@modelcontextprotocol/sdk`, trasporto stdio
3. **Isolamento totale configurazioni** — `-f ~/.bigide/tmux/tmux.conf`, config Ghostty dedicata
4. **MCP bundled compilato** — distribuito dentro `~/.bigide/mcp/`, no build manuale
5. **Memoria basata su fork claude-mem** — formato JSON o SQLite, backup automatico
6. **AppleScript per Chrome e Ghostty** — positioning e fullscreen enforcement
7. **macOS only** (almeno per MVP e Phase 2) — brew come package manager, AppleScript
8. **Ghostty + Kitty graphics protocol** — per anteprime immagini in Yazi
