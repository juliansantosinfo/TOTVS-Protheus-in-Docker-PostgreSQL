#!/bin/bash
#
# ==============================================================================
# SCRIPT: commit-msg.sh
# DESCRIÇÃO: Valida se a mensagem do commit segue o padrão Conventional Commits.
# AUTOR: Julian de Almeida Santos
# DATA: 2025-10-12
# USO: ./scripts/validation/commit-msg.sh <arquivo_da_mensagem>
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

    print_plain() {
        echo "$1"
    }

# ----------------------------------------------------
#   SEÇÃO 2: VALIDAÇÃO DA MENSAGEM
# ----------------------------------------------------

    COMMIT_MSG_FILE="${1:-}"

    if [ -z "$COMMIT_MSG_FILE" ]; then
        print_error "Arquivo de mensagem não fornecido."
        exit 1
    fi

    MSG_CONTENT=$(cat "$COMMIT_MSG_FILE")

    # Regex para Conventional Commits
    # Tipos: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
    # Formato: tipo(escopo opcional): descrição
    PATTERN="^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert|merge)(\(.+\))?: .+$"

    if [[ ! "$MSG_CONTENT" =~ $PATTERN ]]; then
        print_error "Mensagem de commit inválida."
        print_plain "------------------------------------------------------------------"
        print_plain "Sua mensagem: $MSG_CONTENT"
        print_plain "------------------------------------------------------------------"
        print_plain "A mensagem deve seguir o padrão Conventional Commits:"
        print_plain "  <tipo>(<escopo>): <descrição>"
        print_plain ""
        print_plain "Exemplos válidos:"
        print_plain "  feat: adicionar novo endpoint"
        print_plain "  fix(appserver): corrigir variável de ambiente"
        print_plain "  docs: atualizar README"
        print_plain "  ci: ajustar workflow do github"
        print_plain ""
        print_plain "Tipos permitidos: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert"
        exit 1
    fi

    print_success "Mensagem de commit válida."
    exit 0
