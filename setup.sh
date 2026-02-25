#!/usr/bin/env bash
# setup.sh — punto di ingresso legacy, ora tutto è gestito da bin/bigide
# L'installazione dei prerequisiti avviene automaticamente ad ogni avvio.
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/bin/bigide" "$@"
