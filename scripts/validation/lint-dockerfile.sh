#!/bin/bash
#
# ==============================================================================
# SCRIPT: lint-dockerfile.sh
# DESCRIÇÃO: Executa Hadolint em todos os Dockerfiles do projeto.
# AUTOR: Julian de Almeida Santos
# DATA: 2025-10-12
# USO: ./scripts/validation/lint-dockerfile.sh
# ==============================================================================

# --- Configuração de Robustez (Boas Práticas Bash) ---
set -euo pipefail

# ----------------------------------------------------
#   SEÇÃO 1: DEFINICAO DE FUNCOES AUXILIARES
# ----------------------------------------------------

    print_success() {
        echo "✅ $1"
    }

    print_error() {
        echo "❌ $1" >&2
    }

    print_warning() {
        echo "⚠️ $1"
    }

    print_info() {
        echo "🔍 $1"
    }

    print_plain() {
        echo "$1"
    }

# ----------------------------------------------------
#   SEÇÃO 2: VERIFICAÇÃO DE DEPENDÊNCIAS
# ----------------------------------------------------

    if ! command -v hadolint &> /dev/null; then
        print_warning "Hadolint não encontrado. Pule este passo ou instale: https://github.com/hadolint/hadolint"
        exit 0
    fi

# ----------------------------------------------------
#   SEÇÃO 3: EXECUÇÃO DO HADOLINT
# ----------------------------------------------------

    print_info "Executando Hadolint..."

    # Encontra arquivos chamados 'dockerfile' (case insensitive)
    FILES=$(find . -iname "dockerfile" -not -path "./.git/*" -not -path "./totvs/*")

    if [ -z "$FILES" ]; then
        print_success "Nenhum Dockerfile encontrado."
        exit 0
    fi

    # Executa o hadolint
    if echo "$FILES" | xargs hadolint --failure-threshold error; then
        print_success "Hadolint passou."
        exit 0
    else
        print_error "Hadolint encontrou problemas."
        exit 1
    fi
