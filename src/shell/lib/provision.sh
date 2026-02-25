#!/usr/bin/env bash
set -euo pipefail

# Verifica se una directory è vuota (escludendo .DS_Store e .git)
is_dir_empty() {
  local dir="$1"
  [[ -d "$dir" ]] || return 1
  local count
  count=$(ls -A "$dir" | grep -vE "^(.DS_Store|.git)$" | wc -l | xargs)
  [[ "$count" -eq 0 ]]
}

check_auto_provision() {
  local path="$1"

  is_dir_empty "$path" || return 0

  echo ""
  echo -e "${YELLOW}  Cartella vuota rilevata: $(basename "$path")${NC}"
  echo ""
  read -p "  Vuoi inizializzare un nuovo progetto? [s/n]: " confirm
  if [[ "$confirm" == [sSyY] ]]; then
    run_provisioning "$path"
  fi
}

run_provisioning() {
  local path="$1"

  # ── Domanda 1: Nome progetto ──────────────────────────────────────────
  local default_name
  default_name="$(basename "$path")"
  read -p "  Nome progetto [${default_name}]: " project_name
  project_name="${project_name:-$default_name}"

  # ── Domanda 2: Tipo progetto ──────────────────────────────────────────
  echo ""
  echo -e "  ${GREEN}Tipo progetto:${NC}"
  echo "    1) web       (HTML/CSS/JS, React, Next.js...)"
  echo "    2) api       (Node, Python, Go backend)"
  echo "    3) script    (bash, Python utility)"
  echo "    4) altro     (cartella generica)"
  read -p "  Scelta [1-4]: " type_choice
  local project_type
  case "${type_choice:-4}" in
    1) project_type="web"    ;;
    2) project_type="api"    ;;
    3) project_type="script" ;;
    *) project_type="altro"  ;;
  esac

  # ── Domanda 3: BMAD ──────────────────────────────────────────────────
  echo ""
  local install_bmad="n"
  read -p "  Installare BMAD? [s/n]: " install_bmad

  # ── Domanda 4: GitHub repo ───────────────────────────────────────────
  echo ""
  local create_repo="n"
  read -p "  Creare repository GitHub? [s/n]: " create_repo

  # ── Esecuzione ───────────────────────────────────────────────────────
  echo ""
  echo -e "${GREEN}  ▸ Inizializzazione: ${project_name} (${project_type})${NC}"

  # 1. Git init
  if [[ ! -d "$path/.git" ]]; then
    echo -e "  ${YELLOW}▸${NC} git init..."
    git -C "$path" init -q
    echo -e "  ${GREEN}✔${NC} Repository git creato"
  fi

  # 2. Struttura base per tipo
  case "$project_type" in
    web)
      mkdir -p "$path/src" "$path/public" "$path/docs"
      echo "# ${project_name}" > "$path/README.md"
      cat > "$path/.gitignore" << 'GI'
node_modules/
dist/
.next/
.nuxt/
.cache/
.DS_Store
GI
      echo -e "  ${GREEN}✔${NC} Struttura web creata (src/, public/, docs/)"
      ;;
    api)
      mkdir -p "$path/src" "$path/tests" "$path/docs"
      echo "# ${project_name}" > "$path/README.md"
      cat > "$path/.gitignore" << 'GI'
node_modules/
__pycache__/
.env
dist/
.DS_Store
GI
      echo -e "  ${GREEN}✔${NC} Struttura api creata (src/, tests/, docs/)"
      ;;
    script)
      mkdir -p "$path/bin" "$path/lib"
      echo "# ${project_name}" > "$path/README.md"
      cat > "$path/.gitignore" << 'GI'
.DS_Store
*.log
GI
      echo -e "  ${GREEN}✔${NC} Struttura script creata (bin/, lib/)"
      ;;
    *)
      mkdir -p "$path/src" "$path/docs"
      echo "# ${project_name}" > "$path/README.md"
      printf '.DS_Store\n' > "$path/.gitignore"
      echo -e "  ${GREEN}✔${NC} Struttura base creata"
      ;;
  esac

  # 3. BMAD
  if [[ "$install_bmad" == [sSyY] ]]; then
    echo -e "  ${YELLOW}▸${NC} Installazione BMAD..."
    if command -v git >/dev/null 2>&1; then
      mkdir -p "$path/_bmad"
      if git clone --depth 1 https://github.com/bmadcode/BMAD-METHOD.git "$path/_bmad/method" 2>/dev/null; then
        echo -e "  ${GREEN}✔${NC} BMAD installato in _bmad/"
      else
        echo -e "  ${YELLOW}⚠${NC} Clone BMAD fallito (controlla connessione)"
      fi
    fi
  fi

  # 4. GitHub repo
  if [[ "$create_repo" == [sSyY] ]]; then
    if command -v gh >/dev/null 2>&1; then
      echo -e "  ${YELLOW}▸${NC} Creazione repo GitHub..."
      # Commit iniziale necessario per push
      git -C "$path" add -A
      git -C "$path" commit -q -m "init: ${project_name}"
      if gh repo create "$project_name" --public --source="$path" --push 2>/dev/null; then
        echo -e "  ${GREEN}✔${NC} Repository GitHub creato e pushato"
      else
        echo -e "  ${YELLOW}⚠${NC} Creazione repo fallita (esiste già o manca login gh)"
      fi
    else
      echo -e "  ${YELLOW}⚠${NC} GitHub CLI non trovato. Installa con: brew install gh"
    fi
  fi

  # Commit iniziale se non già fatto
  if ! git -C "$path" log --oneline -1 &>/dev/null; then
    git -C "$path" add -A
    git -C "$path" commit -q -m "init: ${project_name}"
    echo -e "  ${GREEN}✔${NC} Commit iniziale creato"
  fi

  echo ""
  echo -e "  ${GREEN}✔ Progetto ${project_name} pronto.${NC}"
  echo ""
  sleep 1
}
