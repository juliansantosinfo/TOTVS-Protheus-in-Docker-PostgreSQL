#!/bin/bash
#
# ==============================================================================
# SCRIPT: secrets.sh
# DESCRIÇÃO: Verifica se há possíveis segredos expostos nos arquivos estagiados.
# AUTOR: Julian de Almeida Santos
# DATA: 2025-10-12
# USO: ./scripts/validation/secrets.sh [--full]
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
#   SEÇÃO 2: PARSE DE ARGUMENTOS
# ----------------------------------------------------

    SCAN_MODE="staged"

    if [[ "${1:-}" == "--full" ]]; then
        SCAN_MODE="full"
    fi

# ----------------------------------------------------
#   SEÇÃO 3: COLETA DE ARQUIVOS
# ----------------------------------------------------

    case "$SCAN_MODE" in
        full)
            print_info "Verificando segredos em todos os arquivos..."
            FILES=$(find . -type f -not -path "./totvs/*" -not -path "./.git/*" -not -path "./node_modules/*")
            ;;
        *)  
            print_info "Verificando segredos em arquivos estagiados..."
            FILES=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || echo "")
            ;;
    esac

    if [ -z "$FILES" ]; then
        print_success "Nenhum arquivo para verificar."
        exit 0
    fi

# ----------------------------------------------------
#   SEÇÃO 4: VALIDAÇÃO DE SEGREDOS
# ----------------------------------------------------

    # Palavras-chave para buscar
    KEYWORDS="PASSWORD|SECRET|KEY|TOKEN|CREDENTIAL"
    # Palavras-chave para negar
    DENY_WORDS="KEY=VALUE"

    # Arquivos permitidos (whitelist)
    WHITELIST=".env.example|versions.env|secrets.sh|README.md|Dockerfile|entrypoint.sh|run.sh"

    EXIT_CODE=0

    for file in $FILES; do
        # Pula se arquivo não existe
        [ ! -f "$file" ] && continue

        # Pula arquivos da whitelist
        if [[ "$file" =~ $WHITELIST ]]; then
            continue
        fi
        
        # Busca por atribuições diretas de segredos (Ex: PASSWORD=123)
        # Ignora linhas de comentário (#)
        if grep -E "^[^#]*($KEYWORDS)\s*=\s*[^\s]+" "$file" | grep -Ev "$DENY_WORDS" > /dev/null 2>&1; then
            print_error "POTENCIAL SEGREDO ENCONTRADO EM: $file"
            print_plain "$(grep -E "^[^#]*($KEYWORDS)\s*=\s*[^\s]+" "$file")"
            EXIT_CODE=1
        fi
    done

    if [ $EXIT_CODE -ne 0 ]; then
        print_warning "Commit bloqueado! Remova os segredos ou use git commit --no-verify se for falso positivo."
        exit 1
    else
        print_success "Nenhum segredo óbvio encontrado."
        exit 0
    fi
