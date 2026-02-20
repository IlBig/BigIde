---
stepsCompleted: ['step-01-init', 'step-02-discovery', 'step-02b-vision', 'step-02c-executive-summary', 'step-03-success', 'step-04-journeys', 'step-05-domain-skipped', 'step-06-innovation', 'step-07-project-type', 'step-08-scoping', 'step-09-functional', 'step-10-nonfunctional', 'step-11-polish', 'step-12-complete']
completedAt: '2026-02-19'
inputDocuments: ['docs/tmux-mcp-ide-spec.md']
documentCounts:
  briefs: 0
  research: 0
  brainstorming: 0
  projectDocs: 1
classification:
  projectType: cli_tool/developer_tool
  domain: general
  complexity: low-medium
  projectContext: greenfield
workflowType: 'prd'
---

# Product Requirements Document — BigIDE

**Author:** Big
**Date:** 2026-02-19

## Executive Summary

**BigIDE** è un ambiente di sviluppo completo orchestrato da terminale, costruito su tmux e Ghostty, dove Claude Code è il motore principale e ha visibilità e controllo su tutti i pannelli tramite un MCP server dedicato in TypeScript.

Il progetto nasce da un bisogno concreto: eliminare la frammentazione di finestre e applicazioni che rende il lavoro di sviluppo frustrante — in particolare per chi, come l'autore, convive con il Parkinson e necessita di un'esperienza interamente controllabile da tastiera e dittatura vocale. Claude Code ha restituito la capacità di programmare; BigIDE è l'ambiente costruito attorno a questa capacità ritrovata.

L'utente target iniziale è l'autore stesso. L'obiettivo a medio termine è rendere il progetto pubblico come dimostrazione di cosa l'intelligenza artificiale può abilitare — anche per sviluppatori con disabilità.

### Cosa Rende Questo Progetto Speciale

- **Flow state accessibile**: un'unica finestra terminale dove tutto avviene tramite tastiera. Navigare file, anteprima, editing, chiedere a Claude Code di implementare codice, aprire il browser — senza mai toccare il mouse
- **AI come co-pilota reale**: Claude Code non suggerisce passivamente. Tramite MCP vede l'output di ogni pannello, invia comandi, monitora build e log, apre Chrome quando necessario. È un agente con pieno controllo operativo
- **Intelligenza dal primo avvio**: su una cartella vuota il sistema rileva l'assenza di progetto, propone l'installazione di BMAD e autoprovision da GitHub, fa quattro domande e configura tutto automaticamente — inclusa la creazione del repository GitHub
- **Esperienza visiva curata**: tema sofisticato, layout stabile ed elegante, status bar informative. Non basta che funzioni — deve essere bello da usare

## Project Classification

| Aspetto | Valore |
|---------|--------|
| **Tipo progetto** | CLI tool / Developer tool (ibrido) |
| **Dominio** | General — strumento di sviluppo software |
| **Complessità** | Low-Medium — nessuna compliance, integrazione multi-tool non banale |
| **Contesto** | Greenfield — nessun codice esistente |

## Success Criteria

### User Success

- **Flow state raggiunto**: l'utente pensa solo a cosa costruire, mai a come operare lo strumento. Nessuna frizione percepita durante una sessione di lavoro
- **Zero-a-progetto senza attriti**: dalla cartella vuota → auto-inizializzazione → descrizione progetto → prime implementazioni funzionanti, senza interruzioni nel flusso
- **Semplicità come metrica**: la tastiera è il canale primario. Il mouse è accettabile in situazioni limitate. L'interazione deve essere intuitiva e richiedere il minimo sforzo cognitivo
- **Autonomia quotidiana**: lo strumento è abbastanza affidabile e completo da essere usato come ambiente di lavoro principale ogni giorno

### Business Success

- **Prodotto completo e curato**: qualità artigianale che si percepisce — non un prototipo, ma uno strumento finito
- **Rilascio pubblico su GitHub**: il successo si misura nella qualità del lavoro, non nelle metriche vanity. Se le stelle arrivano, è un bonus — non un obiettivo
- **Dimostrazione concreta**: il progetto stesso è la prova di cosa l'AI può abilitare per chiunque, incluse persone con disabilità

### Technical Success

- **Layout stabile**: i pannelli mantengono proporzioni e posizioni con Ghostty in fullscreen
- **MCP server affidabile**: Claude Code legge e scrive su tutti i pannelli senza errori o race condition
- **Auto-provisioning funzionante**: rilevamento cartella vuota → installazione BMAD + autoprovision → configurazione automatica → repo GitHub creato
- **Browser integration fluida**: Claude Code apre Chrome quando serve, con layout automatico

### Measurable Outcomes

| Outcome | Metrica |
|---------|---------|
| Sessione senza frizione | Sessione di lavoro completa (1h+) senza dover uscire dall'IDE |
| Keyboard-first | ≥90% delle operazioni eseguibili da tastiera |
| Setup progetto | Da cartella vuota a progetto funzionante in < 5 minuti |
| Stabilità | Nessun crash del layout o dell'MCP server durante una sessione |

## Product Scope & Phased Development

### MVP Strategy

**Approccio:** Experience MVP — il minimo che produce il flow state quotidiano. Non un prototipo dimostrativo, ma un ambiente usabile ogni giorno.

**Risorsa:** Big + Claude Code (il progetto stesso è costruito con il tool che sta costruendo).

**Decisione chiave:** MCP server base incluso nel MVP. Senza di esso Claude Code è cieco e muto — il differenziatore del prodotto non esiste.

### Phase 1 — MVP

Il minimo per sentire il flow state ogni giorno. Setup manuale guidato, accettabile per uso personale.

- Layout tmux completo con tema visivo curato (pannelli: Yazi, Claude Code, terminale, log)
- Ghostty fullscreen forzato all'avvio
- Splash screen con progress bar durante l'avvio
- Status bar superiore (tab, CPU, RAM, data/ora) e git bar (pannello tmux dedicato di 1 riga con gitmux, non tmux status bar)
- Navigazione file con Yazi (tastiera + anteprima)
- Claude Code come pannello principale
- **MCP server base**: `capture_pane`, `send_keys`, `list_panes`, `open_browser` — il minimo per dare a Claude Code occhi e mani
- ANSI stripping e wait-for-prompt — affidabilità MCP
- Integrazione browser Chrome con layout automatico (via MCP)
- Script bootstrap `bigide` per avvio in un comando
- Keybinding navigazione pannelli (prefix + frecce direzionali, prefix+1-5, prefix+z zoom)
- Setup script guidato (non installer automatico completo)

**Journey supportati:** Journey 2 (sessione quotidiana, parziale), Journey 4 (edge case, parziale)

### Phase 2 — Growth

- **Dittatura vocale locale** (Whisper.cpp su Apple Silicon, zero token) — priorità alta
- **`bigide` installer completo e idempotente** — un comando installa tutto su Mac pulito
- Auto-provisioning su cartella vuota (BMAD + autoprovision da GitHub, creazione repo)
- Keybinding git completi (prefix+g table, fzf branch, lazygit popup)
- **Memoria persistente** (fork claude-mem) — autoapprendimento progetto e generale
- **Script autogenerati** da Claude Code in `~/.bigide/scripts/`
- Pannello claude-monitor per usage tracking
- MCP avanzato: `watch_pane`, `create_pane`, `close_pane`, `resize_pane`

**Journey supportati:** Journey 1 (primo avvio), Journey 3 (agente che impara)

### Phase 3 — Vision

- Toggle Perplexity (prefix+p)
- Apertura file in LazyVim overlay da Yazi
- Profili layout per tipo di progetto (web, script, API)
- `bigide --update` per aggiornamento automatico
- Rilascio pubblico su GitHub con documentazione completa
- Community e feedback degli utenti

**Journey supportato:** Journey 5 (utente futuro)

### Risk Mitigation Strategy

- **MCP nel MVP**: aggiunge complessità → mitigazione: solo 4 tool base, non 12+
- **Dipendenza API Anthropic**: MCP può cambiare → mitigazione: server isolato, aggiornabile indipendentemente
- **Complessità integrazione**: molti tool (tmux, Yazi, gitmux, Ghostty, MCP) → mitigazione: sviluppo incrementale per fase
- **Visual polish**: tema può rallentare MVP → mitigazione: tema tmux esistente (es. tokyonight-night), personalizzare dopo
- **Setup manuale MVP**: accettabile per uso personale, installer completo in Phase 2
- **Memory persistence**: deve essere affidabile → mitigazione: fork claude-mem con test, backup automatico, formato semplice (JSON/SQLite)

## User Journeys

### Journey 1: Big — Primo Avvio (Il Ritorno)

**Protagonista:** Big, sviluppatore con Parkinson, ha ritrovato la capacità di programmare grazie a Claude Code.

**Scena iniziale:** Big ha un'idea per un nuovo progetto. Apre il terminale Ghostty, digita `bigide ~/projects/nuova-idea` e preme Invio. Lo schermo si trasforma: pannelli che si aprono in sequenza, un tema scuro elegante si materializza, le status bar si illuminano con informazioni. È già bello.

**Azione crescente:** Il sistema rileva che la cartella è vuota. Un prompt discreto appare nel pannello Claude Code: "Cartella vuota rilevata. Vuoi inizializzare un nuovo progetto?" Big risponde sì. Quattro domande: nome progetto, tipo (web/API/script), vuoi BMAD?, vuoi creare un repo GitHub? Big risponde con la tastiera — o dettando a voce. In meno di due minuti, BMAD e autoprovision si installano da GitHub, il repo viene creato, la struttura del progetto appare nel file browser Yazi a sinistra.

**Climax:** Big guarda lo schermo. Yazi mostra i file del progetto. Claude Code è pronto nel pannello centrale. Il terminale è in basso. La git bar dice `🔀 main │ ✓ clean`. Tutto è lì, tutto è raggiungibile con la tastiera. Non ha toccato il mouse una sola volta. Sorride.

**Risoluzione:** Big descrive a Claude Code cosa vuole costruire. Claude Code inizia a implementare. Il flusso è iniziato — senza frizione, senza setup manuale, senza frustrazioni. Il Parkinson non è un ostacolo. Lo strumento lavora con lui, non contro di lui.

### Journey 2: Big — Sessione di Lavoro Quotidiana (Il Flow)

**Scena iniziale:** Mattina. Big apre Ghostty — si posiziona automaticamente in fullscreen. Il terminale si attacca alla sessione tmux esistente. Tutto è come l'aveva lasciato: il progetto web a cui sta lavorando, i file aperti, la cronologia nel terminale.

**Azione crescente:** Con `prefix+1` salta su Yazi. Le frecce lo portano al componente da modificare. Barra spazio: anteprima rapida dell'immagine del mockup. Si sposta su un file `.tsx`, barra spazio: LazyVim si apre in overlay. Modifica una riga, salva, chiude. Yazi torna visibile, il file è aggiornato.

`prefix+2` — è su Claude Code. "Implementa il componente Header secondo il mockup che abbiamo visto. Usa Tailwind." Claude Code lavora. Legge il file dal pannello Yazi (via MCP), scrive codice, lancia il dev server nel terminale (via MCP send-keys). Il pannello log mostra l'output di Next.js che compila. Claude Code rileva che la build è completata con successo, apre Chrome con il preview — la finestra si posiziona automaticamente 50/50 accanto a Ghostty.

**Climax:** Big guarda il risultato nel browser. Funziona. Torna su Claude Code con un Alt+Tab. "Il padding è troppo stretto, correggilo." Claude Code corregge, il browser si aggiorna automaticamente. Perfetto. `prefix+g c` — popup git: digita il messaggio di commit. `prefix+g p` — push. La git bar si aggiorna: `✓ clean`.

**Risoluzione:** Un'ora è passata. Big non ha mai lasciato l'ambiente. Non ha aperto Finder, non ha cercato finestre perse, non ha perso il filo. Ha pensato solo a cosa costruire. Flow state raggiunto.

### Journey 3: Claude Code — L'Agente che Impara

**Protagonista:** Claude Code, l'agente AI nel pannello centrale, dotato di memoria persistente.

**Scena iniziale:** Big chiede: "Controlla i log del server, c'è un errore che non capisco." Claude Code usa `tmux_capture_pane` sul pannello log. Riceve 50 righe di output, già pulite dai codici ANSI.

**Azione crescente:** Claude Code analizza il log — un errore di connessione al database. Prima di agire, consulta la **memoria persistente** del progetto (sistema ispirato a claude-mem, fork adattato). Trova un record: "2026-02-15: Errore connessione DB → container Docker non avviato → soluzione: `docker compose up -d db`, attendere health check." Claude Code sa già cosa fare. Invia il comando al terminale, monitora con `tmux_watch_pane`. In 10 secondi il database è attivo. Riavvia il dev server. Tutto funziona.

**Climax — Il momento dell'apprendimento:** Una settimana dopo, Big lavora su un nuovo progetto. Errore diverso: un conflitto di porte. Claude Code non ha mai visto questo errore in questo progetto. Diagnostica il problema, trova la porta occupata, la libera, riavvia il server. Poi **salva nella memoria persistente**: la procedura di diagnosi, il comando risolutivo, e genera uno **script di recovery** (`fix-port-conflict.sh`) nella cartella dedicata `~/.bigide/scripts/`. La prossima volta non dovrà nemmeno pensarci — lo script esiste già.

**Struttura della memoria:**
- **Memoria di progetto**: errori risolti, configurazioni specifiche, pattern ricorrenti del progetto corrente
- **Memoria generale**: procedure universali (Docker, porte, permessi, dipendenze) condivise tra tutti i progetti
- **Script autogenerati**: soluzioni eseguibili salvate in cartella dedicata, richiamabili automaticamente quando il pattern si ripresenta

**Risoluzione:** Claude Code non è solo un esecutore — è un agente che accumula esperienza. Ogni errore risolto diventa conoscenza permanente. Ogni sessione lo rende più efficace. Un sistema con autoapprendimento che cresce con Big.

### Journey 4: Big — Quando Qualcosa Si Rompe (Edge Case)

**Premessa:** Ghostty è forzato in fullscreen quando BigIDE è attivo. Lo script `bigide` lo imposta all'avvio. Questo elimina alla radice il problema dei pannelli che si comprimono.

**Scena iniziale:** Big sta lavorando. L'MCP server non risponde — Claude Code riporta un errore quando prova a leggere il pannello log.

**Azione crescente:** Il sistema non è bloccato. I pannelli sono processi indipendenti. Big può ancora usare il terminale manualmente con `prefix+5`. Preme un keybinding dedicato (`prefix+r`) — il sistema esegue `bigide --repair` che riavvia solo il server MCP senza toccare gli altri pannelli né perdere lo stato della sessione.

**Scenario alternativo — Processo crasha:** Il dev server nel pannello log crasha. Claude Code (se MCP funziona) lo rileva tramite `tmux_watch_pane` e propone di riavviarlo. Se Claude Code non è disponibile, Big va sul terminale con `prefix+5` e lo riavvia manualmente.

**Risoluzione:** Il sistema è resiliente per design. Ghostty fullscreen elimina i problemi di resize. Nessun singolo fallimento blocca completamente il lavoro. C'è sempre un percorso di recovery da tastiera, e il comando `--repair` è il "reset chirurgico" che non distrugge nulla.

### Journey 5: Utente Futuro — Scoperta e Primo Uso

**Protagonista:** Marco, sviluppatore freelance, trova BigIDE su GitHub.

**Scena iniziale:** Marco legge il README. Vede il layout, le screenshot, la storia di Big. È incuriosito — usa già tmux e Claude Code, ma in modo frammentato.

**Azione crescente:** Segue le istruzioni di installazione. Esegue `bigide` — l'installer verifica le dipendenze, installa quelle mancanti, configura tutto. Apre Ghostty, il layout appare. Marco è sorpreso dalla pulizia visiva.

**Climax:** Nella prima sessione, Marco chiede a Claude Code di leggere il log di un build fallito in un altro pannello. Claude Code lo fa — senza che Marco debba copiare/incollare nulla. "Questo è quello che mi mancava." Marco capisce il valore: non è un IDE, è un **moltiplicatore di capacità** per Claude Code.

**Risoluzione:** Marco mette una stella su GitHub. Inizia a personalizzare il suo setup. Apre una issue per suggerire un miglioramento. La community inizia a nascere.

### Journey Requirements Summary

| Journey | Capacità Rivelate |
|---------|-------------------|
| **Primo Avvio** | Auto-provisioning, rilevamento cartella vuota, installazione BMAD/autoprovision, creazione repo GitHub, script bootstrap |
| **Sessione Quotidiana** | Ghostty fullscreen forzato, navigazione pannelli (keybinding), Yazi anteprima/editing, Claude Code + MCP, browser integration, git keybinding popup, layout stabile |
| **Agente che Impara** | MCP capture/send/watch, ANSI stripping, wait-for-prompt, **memoria persistente** (progetto + generale), **script autogenerati**, fork claude-mem adattato, diagnostica autonoma |
| **Edge Case / Recovery** | Fullscreen enforcement, repair MCP (`--repair`), fallback manuale, resilienza processo, keybinding recovery |
| **Utente Futuro** | Installazione semplice (`bigide`), README chiaro, configurabilità, estensibilità, community |

## Innovation & Novel Patterns

### Detected Innovation Areas

- **AI-Orchestrated Terminal IDE (nuovo paradigma)**: nessun prodotto esistente dà a un agente AI visibilità e controllo completo su un ambiente di sviluppo multi-pannello via MCP. Claude Code non è inserito nel terminale — è il terminale che è costruito attorno a Claude Code
- **Agente con memoria persistente e autoapprendimento**: ispirato a claude-mem, il sistema accumula conoscenza progetto per progetto e genera script di recovery riutilizzabili. L'agente migliora con l'uso, riducendo il tempo di diagnosi e risoluzione nel tempo
- **Accessibility-first by design**: progettato dal giorno zero per un utente con Parkinson. Keyboard-first, dittatura vocale, zero frammentazione. L'AI non è un'aggiunta — è il meccanismo che rende lo sviluppo possibile
- **Natural language come interfaccia di comando**: l'utente descrive l'intento, l'agente orchestra pannelli, file, build, browser e git. Il linguaggio naturale sostituisce la sequenza manuale di comandi

### Market Context & Competitive Landscape

- **Cursor, Windsurf, Zed**: IDE AI-powered ma con approccio GUI tradizionale. Non danno all'AI il controllo operativo sull'ambiente
- **tmux + Claude Code (uso manuale)**: esiste come pratica nella community, ma senza orchestrazione MCP strutturata
- **Warp terminal**: terminal AI-powered ma focalizzato su suggerimenti, non su controllo completo
- **Nessun concorrente diretto** combina: terminale + AI con controllo MCP + memoria persistente + accessibilità nativa

### Validation Approach

- **Validazione personale**: Big usa l'IDE come ambiente quotidiano. Il test è il flow state raggiunto
- **Confronto before/after**: misurare il tempo per operazioni comuni (setup progetto, debug, deploy) rispetto al workflow frammentato attuale
- **Feedback community**: rilascio pubblico su GitHub come validazione della proposta di valore

## CLI & Developer Tool — Requisiti Specifici

### Project-Type Overview

BigIDE è un ibrido cli_tool/developer_tool: un singolo eseguibile (`bigide`) che funge da installer, launcher e ambiente di sviluppo. L'utente interagisce con un solo comando per tutto il ciclo di vita — dall'installazione iniziale all'uso quotidiano.

### Command Structure

| Comando | Contesto | Azione |
|---------|----------|--------|
| `bigide` | Primo run (dipendenze assenti) | Installa tutto: brew, Ghostty, tmux, Node.js, Yazi, gitmux, lazygit, fzf, claude-monitor, Neovim/LazyVim. Configura tutto in `~/.bigide/` |
| `bigide` | Run successivi (senza sessione) | Lancia Ghostty fullscreen → sessione tmux → layout completo con tutti i pannelli |
| `bigide` | Run successivi (sessione esistente) | Si attacca alla sessione tmux esistente |
| `bigide --repair` | Da terminale interno o esterno | Riavvia MCP server senza toccare sessione/pannelli |
| Comando interno IDE | Dall'interno, keybinding dedicato | Apre nuovo tab → chiede percorso progetto → crea layout completo nel nuovo tab |

### Installation Flow (Primo Run)

1. Verifica dipendenze mancanti
2. Installa brew se assente (macOS)
3. Installa via brew: Ghostty, tmux, Node.js, Neovim, Yazi, gitmux, lazygit, fzf, ffmpegthumbnailer, ImageMagick
4. Installa via npm: Claude Code (`@anthropic-ai/claude-code`)
5. Installa via uv: claude-monitor
6. Scarica e configura: perplexity-cli
7. Crea struttura `~/.bigide/` con tutte le configurazioni
8. Registra MCP server in Claude Code settings
9. Lancia l'IDE per la prima volta

### Configuration Schema — `~/.bigide/`

```
~/.bigide/
├── config.yaml              # Configurazione IDE (tema, piano Claude, preferenze)
├── tmux/
│   ├── tmux.conf            # Configurazione tmux dedicata BigIDE
│   └── themes/              # Temi tmux
├── ghostty/
│   └── config               # Configurazione Ghostty dedicata BigIDE
├── yazi/
│   └── yazi.toml            # Configurazione Yazi + custom previewers
├── nvim/
│   └── init.lua             # Configurazione LazyVim per overlay
├── mcp/
│   └── tmux-mcp/            # MCP server (dist compilato)
├── scripts/
│   └── (script autogenerati da Claude Code)
├── memory/
│   ├── general.db           # Memoria generale Claude Code
│   └── projects/            # Memorie per progetto
└── gitmux.conf              # Configurazione gitmux
```

### Technical Architecture Considerations

- **Isolamento totale**: BigIDE non modifica le configurazioni globali dell'utente. Tmux usa `-f ~/.bigide/tmux/tmux.conf`, Ghostty viene lanciato con config dedicata. Le configurazioni personali dell'utente per tmux/Ghostty/Yazi non vengono toccate
- **Idempotenza installer**: `bigide` può essere rieseguito senza danni — verifica cosa è già installato e salta
- **MCP server bundled**: il server tmux-mcp è compilato e distribuito dentro `~/.bigide/mcp/`, non richiede build manuale
- **Aggiornamento**: `bigide --update` aggiorna l'IDE e le sue dipendenze

### Implementation Considerations

- Lo script principale `bigide` sarà in **shell (bash/zsh)** per massima compatibilità e zero dipendenze al primo run
- L'installer deve funzionare su un **Mac pulito** con solo macOS — nessun prerequisito
- Il MCP server è in **TypeScript**, compilato e distribuito come bundle
- Il sistema di memoria (fork claude-mem) va nella cartella `~/.bigide/memory/`

## Functional Requirements

### Avvio e Gestione Sessione

- **FR1**: L'utente può avviare BigIDE con un singolo comando (`bigide`) che lancia Ghostty in fullscreen e crea la sessione tmux con il layout completo
- **FR2**: BigIDE può rilevare una sessione tmux esistente e riattaccarsi ad essa invece di crearne una nuova
- **FR3**: L'utente può aprire un nuovo progetto in un nuovo tab tmux dall'interno dell'IDE tramite keybinding dedicato, specificando il percorso
- **FR4**: BigIDE può forzare Ghostty in modalità fullscreen all'avvio e mantenerla durante l'uso
- **FR5**: BigIDE può rilevare una cartella vuota e proporre l'inizializzazione automatica del progetto (BMAD, autoprovision, repo GitHub)
- **FR5b**: BigIDE può mostrare una splash screen con progress bar durante l'avvio e l'installazione, comunicando all'utente cosa sta facendo in ogni momento

### Layout e Navigazione Pannelli

- **FR6**: BigIDE può creare e mantenere un layout a pannelli con proporzioni definite e architettura estensibile per supportare nuovi pannelli e disposizioni future
- **FR7**: L'utente può navigare tra i pannelli tramite keybinding direzionali (prefix + frecce direzionali)
- **FR8**: L'utente può saltare direttamente a un pannello specifico tramite keybinding numerici (prefix + 1-5)
- **FR9**: L'utente può espandere un pannello in fullscreen temporaneo (zoom) e tornare al layout con lo stesso keybinding
- **FR10**: BigIDE può ribilanciare automaticamente le proporzioni dei pannelli dopo eventi di resize

### Tabella Keybinding Completa

| Binding | Azione |
|---------|--------|
| `prefix + ← → ↑ ↓` | Navigazione direzionale pannelli |
| `prefix + 1-5` | Salto diretto a pannello specifico |
| `prefix + z` | Zoom/unzoom pannello corrente |
| `prefix + g` | Attiva git mode (key table) |
| `prefix + b` | Apre/posiziona Chrome |
| `prefix + n` | Nuovo progetto in tab |
| `prefix + v` | Toggle dettatura vocale |
| `prefix + ?` | Help completo keybinding |
| `prefix + 500ms` | Which-key banner contestuale |

### Esplorazione File

- **FR11**: L'utente può navigare il file system del progetto tramite file browser (Yazi) usando tastiera e mouse
- **FR12**: L'utente può visualizzare anteprime di immagini direttamente nel file browser
- **FR13**: L'utente può visualizzare anteprime di file Office/PDF tramite Quick Look macOS nel file browser
- **FR14**: L'utente può aprire un file nell'editor integrato (LazyVim overlay) dal file browser
- **FR15**: L'utente può salvare e chiudere l'editor overlay tornando al file browser con il file aggiornato

### Agente AI (Claude Code + MCP)

- **FR16**: Claude Code può catturare il contenuto visibile di qualsiasi pannello tmux tramite MCP
- **FR17**: Claude Code può inviare comandi e sequenze di tasti a qualsiasi pannello tmux tramite MCP
- **FR18**: Claude Code può elencare tutti i pannelli della sessione con informazioni su dimensioni, processo attivo e stato
- **FR19**: Il server MCP può rimuovere i codici ANSI dall'output catturato prima di restituirlo a Claude Code
- **FR20**: Il server MCP può attendere la ricomparsa del prompt shell dopo l'invio di un comando prima di restituire il risultato (wait-for-prompt)
- **FR21**: Claude Code può creare, chiudere e ridimensionare pannelli tmux tramite MCP
- **FR22**: Claude Code può monitorare un pannello con catture periodiche e rilevamento differenze (watch)

### Integrazione Browser

- **FR23**: Claude Code può aprire un URL in Chrome tramite MCP, con posizionamento automatico della finestra
- **FR24**: BigIDE può presentare una scelta di layout browser alla prima apertura della sessione (50/50 o fullscreen separato)
- **FR25**: BigIDE può posizionare Chrome e Ghostty secondo il layout scelto tramite AppleScript

### Git e Version Control

- **FR26**: La git bar (implementata come pannello tmux dedicato di 1 riga, NON come tmux status bar) può mostrare informazioni git in tempo reale (branch, stato, ultimo commit, diff count)
- **FR27**: L'utente può cambiare branch tramite keybinding con selezione fuzzy in popup
- **FR28**: L'utente può creare un commit tramite keybinding con popup per il messaggio
- **FR29**: L'utente può eseguire push tramite keybinding dedicato
- **FR30**: L'utente può visualizzare status e log git tramite keybinding con popup
- **FR31**: L'utente può aprire una TUI git completa (lazygit) in popup a schermo quasi pieno
- **FR32**: L'utente può interagire con le funzionalità git anche tramite mouse sulla barra git e sui popup

### Monitoraggio e Status

- **FR33**: La barra di stato superiore può mostrare la lista dei tab/progetti, uso CPU, uso RAM e data/ora
- **FR34**: Il pannello usage monitor può mostrare il consumo token di Claude Code in tempo reale con progress bar e predizioni
- **FR35**: BigIDE può aggiornare le informazioni delle barre di stato a intervalli configurabili

### Configurazione e Personalizzazione

- **FR36**: BigIDE può mantenere tutte le configurazioni in una cartella dedicata (`~/.bigide/`) senza modificare configurazioni globali dell'utente
- **FR37**: L'utente può personalizzare il tema visivo dell'IDE tramite file di configurazione
- **FR38**: BigIDE può applicare configurazioni dedicate a tmux, Ghostty, Yazi e Neovim isolate da quelle personali

### Installazione e Manutenzione

- **FR39**: BigIDE può verificare e installare automaticamente tutte le dipendenze necessarie al primo avvio (brew, Ghostty, tmux, Node.js, Yazi, gitmux, Claude Code, ecc.)
- **FR40**: L'installer può essere rieseguito in modo idempotente senza danni alle installazioni esistenti
- **FR41**: L'utente può riparare il server MCP senza perdere la sessione di lavoro (`bigide --repair`)
- **FR42**: L'utente può aggiornare BigIDE e le sue dipendenze tramite un singolo comando

### Memoria e Autoapprendimento

- **FR43**: Claude Code può salvare procedure risolutive e pattern nella memoria persistente del progetto
- **FR44**: Claude Code può consultare la memoria persistente prima di diagnosticare un problema già incontrato
- **FR45**: Claude Code può generare script di recovery riutilizzabili e salvarli in una cartella dedicata
- **FR46**: Il sistema di memoria può distinguere tra conoscenza specifica del progetto e conoscenza generale condivisa tra progetti

### Input Vocale

- **FR47**: L'utente può utilizzare la dittatura vocale locale (zero token) come canale di input alternativo alla tastiera — ultima priorità assoluta di implementazione. Nota: la UX progetta per la visione completa (voce come input primario), ma l'implementazione procede keyboard-first nell'MVP con voce come ultima feature di Phase 2

### Scopribilità e Onboarding

- **FR48**: BigIDE può mostrare un banner contestuale con i keybinding disponibili dopo il prefix (which-key), attivato automaticamente dopo 500ms di attesa post-prefix, e un help completo tramite `prefix + ?`

## Non-Functional Requirements

### Performance

- **NFR1**: Le operazioni MCP (capture_pane, send_keys) devono completarsi in < 500ms percepiti dall'utente
- **NFR2**: Il meccanismo wait-for-prompt deve rilevare il prompt entro 5 secondi o restituire timeout
- **NFR3**: La navigazione tra pannelli (keybinding) deve essere istantanea (< 100ms)
- **NFR4**: L'avvio dell'IDE deve mostrare una splash screen con progress bar che comunica lo stato di ogni fase. Il tempo di avvio non è critico purché l'utente abbia feedback visivo continuo
- **NFR5**: Le status bar devono aggiornarsi senza impatto percepibile sulle prestazioni degli altri pannelli

### Accessibilità

- **NFR6**: ≥90% delle operazioni dell'IDE devono essere eseguibili esclusivamente da tastiera
- **NFR7**: Tutti i keybinding devono essere eseguibili con una mano (o sequenziali, non chord complessi simultanei) per minimizzare lo sforzo motorio
- **NFR8**: I testi nelle status bar e nei pannelli devono avere contrasto sufficiente per leggibilità in tutte le condizioni di luce
- **NFR9**: Il mouse è supportato SOLO nei popup interattivi (lazygit, fzf) e nel file browser Yazi, NON nel layout principale o nelle barre di stato
- **NFR10**: L'interfaccia non deve richiedere movimenti precisi del mouse — target di click ampi, nessun drag & drop obbligatorio

### Affidabilità

- **NFR11**: Una sessione di lavoro di 1+ ore non deve presentare crash del layout o del server MCP
- **NFR12**: Il fallimento di un singolo componente (MCP, Yazi, log) non deve bloccare gli altri pannelli
- **NFR13**: Il layout deve mantenere le proporzioni corrette per l'intera sessione con Ghostty in fullscreen
- **NFR14**: L'installer deve essere idempotente — riesecuzioni multiple non devono causare danni o inconsistenze
- **NFR15**: La memoria persistente dell'agente deve sopravvivere a crash della sessione senza perdita di dati

### Integrazione

- **NFR16**: Il server MCP deve funzionare con Claude Code via trasporto stdio senza configurazione manuale dopo l'installazione
- **NFR17**: BigIDE deve funzionare con tmux ≥ 3.3 e Ghostty versione stabile corrente
- **NFR18**: L'integrazione Chrome via AppleScript deve funzionare su macOS Ventura e successivi
- **NFR19**: L'aggiornamento di una dipendenza esterna (tmux, Yazi, Claude Code) non deve rompere BigIDE — degradazione graceful con messaggio chiaro
