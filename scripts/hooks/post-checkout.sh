#!/bin/bash
#
# ==============================================================================
# SCRIPT: post-checkout.sh
# DESCRIÇÃO: Limpa arquivos não versionados dos diretórios protheus e protheus_data
#            após mudança de branch.
# AUTOR: Julian de Almeida Santos
# DATA: 2025-01-15
# USO: Executado automaticamente pelo Git após checkout
# ==============================================================================

# --- Configuração de Robustez (Boas Práticas Bash) ---
set -euo pipefail

# ----------------------------------------------------
#   SEÇÃO 1: DEFINICAO DE FUNCOES AUXILIARES
# ----------------------------------------------------

    print_success() {
        echo "✅ $1"
    }

    print_info() {
        echo "🧹 $1"
    }

    print_warning() {
        echo "⚠️ $1"
    }

# ----------------------------------------------------
#   SEÇÃO 2: PARÂMETROS DO HOOK
# ----------------------------------------------------

    # $1 = ref anterior
    # $2 = ref novo
    # $3 = flag (1 = mudança de branch, 0 = checkout de arquivo)

    PREV_HEAD=$1
    NEW_HEAD=$2
    BRANCH_CHECKOUT=$3

    # Só executa em mudança de branch
    if [ "$BRANCH_CHECKOUT" != "1" ]; then
        exit 0
    fi

# ----------------------------------------------------
#   SEÇÃO 3: LIMPEZA DE DIRETÓRIOS
# ----------------------------------------------------

    # Chama o script clean.sh
    ./clean.sh
