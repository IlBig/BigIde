# AI Runner Selector — Discussione Team BMAD

**Data:** 2026-02-25
**Partecipanti:** Winston (Architect), John (PM), Amelia (Dev), Mary (Analyst), Sally (UX), Murat (Test Architect)

---

## Contesto

Big vuole un popup tmux (stile Tokyo Night) per selezionare dinamicamente il runner AI in BigIDE. Abbonamenti disponibili:

| Abbonamento | Auth | Token su disco |
|---|---|---|
| **Claude MAX** | OAuth | `~/.claude/.credentials.json` |
| **OpenAI (Codex)** | OAuth | `~/.codex/auth.json` |

Il proxy **ccproxy** (starbased-co) intercetta le chiamate Claude Code e le instrada verso il provider scelto via LiteLLM.

---

## Decisioni prese da Big

1. **Keybinding:** non bloccante, si sistema dopo
2. **Spike tecnico:** priorità assoluta — verificare ccproxy + OpenAI OAuth prima di costruire la UI
3. **Modelli:** solo pre-testati e verificati con tool_use
4. **Stato attuale:** installazione ccproxy da zero

---

## Preoccupazioni architetturali (Winston)

### 1. Disallineamento ccproxy.sh
Il file `ccproxy.sh` attuale cerca un binario **Go** (`go install github.com/starbased-co/ccproxy@latest`), ma ccproxy è **Python** installabile via `uv tool install claude-ccproxy --with 'litellm[proxy]'`. La funzione `install_ccproxy()` va riscritta completamente.

### 2. Restart del proxy
Si dice "1-2 secondi, trasparente", ma se Claude Code ha una richiesta in-flight durante il restart? Serve un meccanismo di drain o attendere idle prima di switchare.

### 3. Token OAuth scaduti
I token in `~/.codex/auth.json` e `~/.claude/.credentials.json` scadono. ccproxy li legge all'avvio e li caccia. Se scadono durante una sessione lunga, il proxy smette di funzionare silenziosamente.

---

## Analisi di rischio (Murat)

| Rischio | Probabilità | Impatto | Mitigazione |
|---------|------------|---------|-------------|
| Token OAuth scaduto | Alta (sessioni lunghe) | Claude Code si blocca | Refresh check prima del switch |
| ccproxy non stabile | Media | Feature inutilizzabile | Pin versione specifica |
| Restart perde richiesta in-flight | Bassa | Perdita singola risposta | Aspettare idle prima di restart |
| Modello non supporta tool_use | Alta (certi modelli) | Claude Code crasha | Filtrare solo modelli compatibili |

### Modelli compatibili con tool_use (verificati)

- **Anthropic**: Sonnet 4.5, Opus 4.5, Haiku 4.5
- **OpenAI**: GPT-5.x (Codex), GPT-4o
- **Gemini**: Gemini 2.0 Pro (con limitazioni note su tool_use complesso)

---

## Due scenari a confronto

### Scenario A — ccproxy (proxy unico)

```
Claude Code → ccproxy:4000 → LiteLLM → Anthropic API / OpenAI API
```

- **Pro**: un solo client (Claude Code), switch trasparente, UX uniforme
- **Contro**: dipendenza esterna fragile, traduzione API potenzialmente lossy, non tutti i tool funzionano

### Scenario B — CLI switch (due client nativi)

```
Popup → scelta "Claude" → lancia `claude` nel pane
Popup → scelta "OpenAI" → lancia `codex` nel pane
```

- **Pro**: zero dipendenze extra, ogni CLI è nativo per il suo provider, compatibilità tool_use al 100%
- **Contro**: UX diversa tra i due, configurazioni separate, due mondi da imparare

### Confronto rischi

| Criterio | Scenario A (ccproxy) | Scenario B (CLI switch) |
|----------|---------------------|------------------------|
| Complessità setup | Alta (Python + LiteLLM + YAML) | Bassa (solo due binari) |
| Affidabilità | Media (dipende da progetto terzo) | Alta (client ufficiali) |
| Compatibilità tool_use | Rischio traduzione | Nativa al 100% |
| Esperienza utente | Uniforme (sempre Claude Code UI) | Diversa (due TUI diverse) |
| Manutenibilità | Fragile (ccproxy si aggiorna) | Stabile |
| Flessibilità modelli | Alta (qualsiasi modello LiteLLM) | Bassa (solo modelli del CLI) |

---

## Dubbio critico (Mary)

**`oat_sources` con OpenAI OAuth è verificato?** La documentazione di ccproxy mostra solo l'esempio con `anthropic`. Nessuna prova che `oat_sources.openai` con token da `~/.codex/auth.json` funzioni realmente. Potrebbe essere necessario un formato diverso o un hook custom.

Inoltre: ccproxy è marcato come "main branch may not be stable for all Claude Code versions". Costruire su sabbie mobili è rischioso → **pinnare una versione specifica testata**.

---

## Proposta UX popup (Sally)

Selettore con **gruppi visivi** separati da header non selezionabili (scala bene con nuovi provider):

```
┌──────────────────────────────────────────────┐
│         Seleziona Runner AI                  │
│                                              │
│  ── Claude MAX ───────────────────────────   │
│  ▸  claude-sonnet-4-5  (default)             │
│     claude-opus-4-5                          │
│     claude-haiku-4-5                         │
│                                              │
│  ── OpenAI ───────────────────────────────   │
│     gpt-5.3-codex                            │
│     gpt-5.1-codex-mini                       │
│                                              │
└──────────────────────────────────────────────┘
```

---

## Strategia approvata dal team

### Fase 1 — Spike tecnico (priorità)

Verificare prima che la fondazione regga:

1. Installare ccproxy da zero via `uv tool install claude-ccproxy --with 'litellm[proxy]'`
2. Configurare con Claude MAX OAuth (`~/.claude/.credentials.json`)
3. Configurare con OpenAI Codex OAuth (`~/.codex/auth.json`)
4. Verificare che Claude Code funzioni attraverso il proxy
5. Verificare che il switch modello (restart proxy) sia trasparente
6. Verificare compatibilità tool_use con modelli OpenAI via proxy

### Fase 2 — Implementazione (se spike OK)

Se lo spike conferma la fattibilità:

1. Riscrivere `ccproxy.sh` per il vero ccproxy Python
2. Generazione programmatica YAML (`ccproxy.yaml` + `config.yaml`)
3. Popup selettore modello (stile Tokyo Night, pattern `show_session_dialog`)
4. Keybinding tmux
5. Indicatore modello attivo nella status bar

### Fallback — Scenario B

Se lo spike fallisce (traduzione lossy, token incompatibili, crash), si implementa il CLI switch con popup che lancia `claude` o `codex` nel pane. La UI popup resta identica, cambia solo il backend.

---

## Artefatti da produrre

1. **Spike Tecnico** — procedura passo-passo verificabile
2. **PRD** — requisiti completi della feature "AI Runner Selector"
3. **Architettura Tecnica** — componenti, flussi, file coinvolti
4. **User Stories** — story implementabili con acceptance criteria
5. **Test Plan** — come verificare che tutto funzioni e non regredisca

---

## Dettagli tecnici ccproxy

### Configurazione ccproxy (due file YAML in `~/.ccproxy/`)

**`ccproxy.yaml`** — regole di routing + credenziali:
```yaml
ccproxy:
  debug: true
  oat_sources:
    anthropic: "jq -r '.claudeAiOauth.accessToken' ~/.claude/.credentials.json"
    openai: "jq -r '.tokens.access_token' ~/.codex/auth.json"
  hooks:
    - ccproxy.hooks.rule_evaluator
    - ccproxy.hooks.model_router
    - ccproxy.hooks.forward_oauth
  rules:
    - name: background
      rule: ccproxy.rules.MatchModelRule
      params:
        - model_name: claude-haiku-4-5-20251001
    - name: think
      rule: ccproxy.rules.ThinkingRule

litellm:
  host: 127.0.0.1
  port: 4000
  num_workers: 4
```

**`config.yaml`** — deployment modelli:
```yaml
model_list:
  - model_name: default
    litellm_params:
      model: anthropic/claude-sonnet-4-5-20250929
      api_base: https://api.anthropic.com

  - model_name: think
    litellm_params:
      model: anthropic/claude-opus-4-5-20251101
      api_base: https://api.anthropic.com

  - model_name: background
    litellm_params:
      model: anthropic/claude-haiku-4-5-20251001
      api_base: https://api.anthropic.com

litellm_settings:
  callbacks:
    - ccproxy.handler
general_settings:
  forward_client_headers_to_llm_api: true
```

### CLI ccproxy

```bash
ccproxy install [--force]        # Crea config in ~/.ccproxy
ccproxy start [--detach]         # Avvia proxy LiteLLM
ccproxy stop                     # Ferma proxy
ccproxy status [--json]          # Health check
ccproxy logs [-f] [-n LINES]     # Log proxy
ccproxy run <command> [args...]  # Esegue comando con env proxy
```

### Credenziali OAuth su disco

| File | Contenuto | Formato |
|------|-----------|---------|
| `~/.claude/.credentials.json` | `claudeAiOauth.accessToken` | JSON |
| `~/.codex/auth.json` | `tokens.access_token` | JSON |

### Installazione ccproxy

```bash
# Metodo raccomandato
uv tool install claude-ccproxy --with 'litellm[proxy]'

# Alternativa pip
pip install claude-ccproxy 'litellm[proxy]'
```
