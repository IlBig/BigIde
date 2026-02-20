# MdM Memory Pack — BigIDE

Questo file consolida i riferimenti critici BMAD da tenere in memoria durante l'implementazione.

## Fonti caricate
- `docs/planning-artifacts/prd.md`
- `docs/planning-artifacts/prd-decisions-log.md`
- `docs/planning-artifacts/architecture.md`
- `docs/planning-artifacts/epics.md`
- `docs/planning-artifacts/implementation-readiness-report-2026-02-19.md`
- `docs/tmux-mcp-ide-spec.md`

## Decisioni operative vincolanti
- Config runtime isolata in `~/.bigide/`.
- Layout dichiarativo JSON come base.
- MCP MVP con 4 tool: `capture_pane`, `send_keys`, `list_panes`, `open_browser`.
- Naming: bash snake_case, TypeScript camelCase.
- Gestione errori fail-open.
- Dittatura vocale ultima priorità (Epic 10).
- Claude Code deve passare attraverso ccproxy in modalità trasparente quando disponibile.

## Definizione di completamento globale
Un Epic è completato solo quando:
1. Tutte le story dell'epic sono marcate done.
2. Acceptance criteria verificate con check ripetibili.
3. Artefatti runtime/config aggiornati senza rompere la compatibilità.
4. Log diagnostici disponibili.
