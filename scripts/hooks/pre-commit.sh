#!/bin/bash
# ==============================================================================
# SCRIPT: scripts/hooks/pre-commit.sh
# DESCRIÇÃO: Orquestrador de validações disparado pelo Git Pre-commit Hook.
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

    print_info() {
        echo "🚀 $1"
    }

# ----------------------------------------------------
#   SEÇÃO 2: EXECUÇÃO DAS VALIDAÇÕES
# ----------------------------------------------------

    print_info "Iniciando validações de pré-commit..."

    # 1. Validação de Versões
    ./scripts/validation/versions.sh || exit 1

    # 2. Validação de Scripts Shell (ShellCheck)
    ./scripts/validation/lint-shell.sh || exit 1

    # 3. Escaneamento de Segredos
    ./scripts/validation/secrets.sh || exit 1

    # 4. Validação de .env.example
    ./scripts/validation/env.sh || exit 1

    # 5. Linting de Dockerfiles (Hadolint)
    ./scripts/validation/lint-dockerfile.sh || exit 1

    print_success "Todas as validações passaram!"
    exit 0
