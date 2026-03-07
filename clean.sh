#!/bin/bash
#
# ==============================================================================
# SCRIPT: clean.sh
# DESCRIÇÃO: Limpa arquivos não versionados dos diretórios dbaccess e packages
# AUTOR: Julian de Almeida Santos
# DATA: 2025-01-15
# USO: ./clean.sh
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
#   SEÇÃO 2: LIMPEZA DE DIRETÓRIOS
# ----------------------------------------------------

    DIRS_TO_CLEAN=("packages")

    print_info "Iniciando limpeza de arquivos não versionados..."

    for dir in "${DIRS_TO_CLEAN[@]}"; do
        if [ -d "$dir" ]; then
            print_info "Limpando arquivos não versionados em $dir..."
            
            # Remove arquivos não versionados e ignorados
            git clean -fdx "$dir" > /dev/null 2>&1 || true
            
            print_success "Diretório $dir limpo."
        else
            print_warning "Diretório $dir não encontrado."
        fi
    done

    print_success "Limpeza concluída!"
