#!/usr/bin/env bash
set -euo pipefail

# Verifica se una directory è vuota (escludendo .DS_Store e .git)
is_dir_empty() {
  local dir="$1"
  [[ -d "$dir" ]] || return 1
  # Conta i file escludendo quelli nascosti comuni o gestiti
  local count
  count=$(ls -A "$dir" | grep -vE "^(.DS_Store|.git)$" | wc -l | xargs)
  [[ "$count" -eq 0 ]]
}

check_auto_provision() {
  local path="$1"
  
  if is_dir_empty "$path"; then
    echo -e "
${YELLOW}detected empty directory: $path${NC}"
    read -p "Vuoi inizializzare un nuovo progetto BigIDE qui? (y/n): " confirm
    if [[ "$confirm" == [yY] ]]; then
      run_provisioning "$path"
    fi
  fi
}

run_provisioning() {
  local path="$1"
  local project_name
  project_name=$(basename "$path")

  echo -e "${GREEN}Inizializzazione progetto: $project_name...${NC}"
  
  # 1. Inizializza Git
  if [[ ! -d "$path/.git" ]]; then
    info "Inizializzazione Git..."
    git -C "$path" init
  fi

  # 2. Proposta BMAD (Placeholder - simula la creazione di una struttura base)
  info "Creazione struttura base..."
  mkdir -p "$path/src" "$path/docs"
  echo "# $project_name" > "$path/README.md"
  
  # 3. GitHub Repo (richiede gh CLI già installata e autenticata)
  if command -v gh >/dev/null 2>&1; then
    read -p "Vuoi creare un repository GitHub per questo progetto? (y/n): " gh_confirm
    if [[ "$gh_confirm" == [yY] ]]; then
      info "Creazione repository GitHub..."
      gh repo create "$project_name" --public --source="$path" --push || warn "Impossibile creare il repo (forse esiste già o manca login)"
    fi
  fi

  info "Provisioning completato."
}
