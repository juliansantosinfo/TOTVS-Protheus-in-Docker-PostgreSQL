#!/bin/bash
# ==============================================================================
# SCRIPT: scripts/hooks/commit-msg.sh
# DESCRIÇÃO: Wrapper para validação de mensagem de commit.
# ==============================================================================

# --- Configuração de Robustez (Boas Práticas Bash) ---
set -euo pipefail

./scripts/validation/commit-msg.sh "$1"
