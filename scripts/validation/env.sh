#!/bin/bash
#
# ==============================================================================
# SCRIPT: env.sh
# DESCRIÇÃO: Garante que todas as chaves do .env local estejam no .env.example.
# AUTOR: Julian de Almeida Santos
# DATA: 2025-10-12
# USO: ./scripts/validation/env.sh
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
#   SEÇÃO 2: DETECÇÃO DE ARQUIVOS
# ----------------------------------------------------

    if [ -f ".env" ] && [ -f ".env.example" ]; then
        ENV_FILE=".env"
        EXAMPLE_FILE=".env.example"
    elif [ -f "../../.env" ] && [ -f "../../.env.example" ]; then
        ENV_FILE="../../.env"
        EXAMPLE_FILE="../../.env.example"
    else
        print_warning "Arquivos .env ou .env.example não encontrados. Pulando validação."
        exit 0
    fi

# ----------------------------------------------------
#   SEÇÃO 3: VALIDAÇÃO
# ----------------------------------------------------

    print_info "Comparando $ENV_FILE com $EXAMPLE_FILE..."

    # Extrai apenas as chaves (antes do =)
    KEYS_ENV=$(grep -oE '^[A-Z0-9_]+=' "$ENV_FILE" | cut -d= -f1 | sort)
    KEYS_EXAMPLE=$(grep -oE '^[A-Z0-9_]+=' "$EXAMPLE_FILE" | cut -d= -f1 | sort)

    # Compara usando diff
    DIFF=$(comm -23 <(echo "$KEYS_ENV") <(echo "$KEYS_EXAMPLE"))

    if [ -n "$DIFF" ]; then
        print_error "As seguintes variáveis estão no .env mas FALTAM no .env.example:"
        print_plain "$DIFF"
        print_info "Por favor, adicione-as ao .env.example para manter a documentação atualizada."
        exit 1
    else
        print_success ".env.example está atualizado."
        exit 0
    fi
