# Current Cycle Tasks (Iterazione 3)

## Completato in questa iterazione
- Integrato `ccproxy` sotto il cofano tramite launcher trasparente `~/.bigide/scripts/launch-claude.sh`.
- Aggiunta libreria `ccproxy.sh` con detection + installazione automatica multi-strategia (brew/go/sorgenti).
- Aggiornato `bigide` con comando `--install-ccproxy` e wiring runtime per supporto proxy trasparente.
- Estesa configurazione default con blocco `ccproxy` (`mode`, `transparent`, `repo`).
- Update flow ora prova a garantire presenza `ccproxy` quando la modalità trasparente è attiva.

## Prossimo ciclo (priorità alta)
1. Integrare AppleScript reale per fullscreen Ghostty/Chrome e scelta layout browser sessione (Story 4.2).
2. Introdurre test shell automatizzati e smoke test MCP locali con runner dedicato.
3. Rendere verificabile in CI l'installazione ccproxy con fixture offline/mocked.
4. Completare Story 1.6 (which-key banner persistente, non solo messaggio).

## Regola operativa
Ogni nuovo ciclo deve:
- chiudere almeno una story completa end-to-end,
- aggiornare `sprint-master-checklist.md`,
- lasciare una task list esplicita per il ciclo successivo.
