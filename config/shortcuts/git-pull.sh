#!/usr/bin/env bash
# @name: Git Pull
# @desc: Scarica aggiornamenti da tutti i remote
# @icon:
set -euo pipefail
# Usa la directory corrente del terminale (non forzare cd)

echo "Fetching all remotes..."
git fetch --all
echo ""
git pull
echo ""
echo "✓ Aggiornamento completato"
echo ""
echo "Premi un tasto per chiudere..."
read -rsn1
