#!/bin/bash
#
# ==============================================================================
# SCRIPT: lint-shell.sh
# DESCRIÇÃO: Executa ShellCheck em todos os arquivos .sh do projeto.
# AUTOR: Julian de Almeida Santos
# DATA: 2025-10-12
# USO: ./scripts/validation/lint-shell.sh
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

    if ! command -v shellcheck &> /dev/null; then
        print_warning "ShellCheck não encontrado. Pule este passo ou instale: 'sudo apt install shellcheck'"
        exit 0
    fi

# ----------------------------------------------------
#   SEÇÃO 3: EXECUÇÃO DO SHELLCHECK
# ----------------------------------------------------

    print_info "Executando ShellCheck..."

    # Encontra arquivos .sh, ignorando pastas desnecessárias
    FILES=$(find . -name "*.sh" -not -path "./.git/*" -not -path "./node_modules/*" -not -path "./totvs/*")

    if [ -z "$FILES" ]; then
        print_success "Nenhum script shell encontrado."
        exit 0
    fi

    # Executa o shellcheck
    if echo "$FILES" | xargs shellcheck --severity=error; then
        print_success "ShellCheck passou."
        exit 0
    else
        print_error "ShellCheck encontrou erros."
        exit 1
    fi
