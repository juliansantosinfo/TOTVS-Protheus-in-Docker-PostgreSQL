#!/bin/bash
#
# ==============================================================================
# SCRIPT: push.sh
# DESCRIÇÃO: Envia a imagem Docker do PostgreSQL TOTVS Protheus para o Docker Hub.
# AUTOR: Julian de Almeida Santos
# DATA: 2025-10-12
# USO: ./push.sh [OPTIONS]
#
# OPÇÕES:
#   --no-latest                 Não faz push da tag 'latest'
#   --tag=<TAG>                 Define uma tag customizada para push
#   -h, --help                  Exibe esta mensagem de ajuda
#
# EXEMPLOS:
#   ./push.sh
#   ./push.sh --no-latest
#   ./push.sh --tag=custom-tag
# ==============================================================================

# --- Configuração de Robustez (Boas Práticas Bash) ---
# -e: Sai imediatamente se um comando falhar.
# -u: Trata variáveis não definidas como erro.
# -o pipefail: Garante que um pipeline (ex: cat | tar) falhe se qualquer comando falhar.
set -euo pipefail

# ----------------------------------------------------
#   SEÇÃO 1: DEFINICAO DE FUNCOES AUXILIARES
# ----------------------------------------------------

    # --- Funções de Impressão ---
    print_success() {
        local message="$1"
        echo "✅ $message"
    }

    print_error() {
        local message="$1"
        echo "🚨 Erro: $message" >&2
    }

    print_warning() {
        local message="$1"
        echo "⚠️ Aviso: $message"
    }

    print_info() {
        local message="$1"
        echo "ℹ️ $message"
    }

    print_docker() {
        local message="$1"
        echo "🐳 $message"
    }

    show_help() {
        cat << EOF
USO: ./push.sh [OPTIONS]

OPÇÕES:
  --no-latest                 Não faz push da tag 'latest'
  --tag=<TAG>                 Define uma tag customizada para push
  -h, --help                  Exibe esta mensagem de ajuda

EXEMPLOS:
  ./push.sh
  ./push.sh --no-latest
  ./push.sh --tag=custom-tag

EOF
        exit 0
    }

    check_versions() {
        if [ -f "versions.env" ]; then
            # shellcheck source=versions.env
            source "versions.env"
            print_info "Versões carregadas do 'versions.env'"
        else
            print_error "Arquivo 'versions.env' não encontrado."
            exit 1
        fi
    }

# ----------------------------------------------------
#   SEÇÃO 2: PARSE DE ARGUMENTOS
# ----------------------------------------------------

    PUSH_LATEST="true"
    CUSTOM_TAG=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            --no-latest)
                PUSH_LATEST="false"
                shift
                ;;
            --tag=*)
                CUSTOM_TAG="${1#*=}"
                shift
                ;;
            -h|--help)
                show_help
                ;;
            *)
                print_error "Opção desconhecida: $1"
                show_help
                ;;
        esac
    done

# ----------------------------------------------------
#   SEÇÃO 3: DEFINIÇÕES VARIAVEIS
# ----------------------------------------------------

    check_versions

    # Detecta branch atual (local ou GitHub Actions)
    if [[ "${GITHUB_ACTIONS:-false}" == "true" ]]; then
        CURRENT_BRANCH="${GITHUB_REF_NAME:-}"
        print_info "GitHub Actions detectado - Branch: ${CURRENT_BRANCH}"
    elif command -v git &> /dev/null; then
        CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")
        [[ -n "$CURRENT_BRANCH" ]] && print_info "Branch local detectada: ${CURRENT_BRANCH}"
    else
        CURRENT_BRANCH=""
    fi

    [[ -z "$CURRENT_BRANCH" ]] && print_warning "Não foi possível detectar a branch"

    # Desabilita push da tag 'latest' se não estiver em main/master
    if [[ "$PUSH_LATEST" == "true" ]] && [[ -n "$CURRENT_BRANCH" ]]; then
        if [[ "$CURRENT_BRANCH" != "main" ]] && [[ "$CURRENT_BRANCH" != "master" ]]; then
            PUSH_LATEST="false"
            print_warning "Tag 'latest' desabilitada - branch atual: ${CURRENT_BRANCH}"
        fi
    fi

    # Define a tag final
    if [[ -n "$CUSTOM_TAG" ]]; then
        FULL_TAG="$CUSTOM_TAG"
    else
        FULL_TAG="${DOCKER_USER}/${POSTGRES_IMAGE_NAME}:${POSTGRES_VERSION}"
    fi

    LATEST_TAG="${DOCKER_USER}/${POSTGRES_IMAGE_NAME}:latest"

    # Validação de variáveis
    if [[ -z "${POSTGRES_VERSION:-}" ]] || [[ -z "${POSTGRES_IMAGE_NAME:-}" ]] || [[ -z "${DOCKER_USER:-}" ]]; then
        print_error "Configurações incompletas em versions.env"
        exit 1
    fi

# ----------------------------------------------------
#   SEÇÃO 4: VERIFICAÇÃO DO DOCKER
# ----------------------------------------------------

    print_info "Verificando se o Docker está instalado e funcionando..."

    if ! command -v docker &> /dev/null; then
        print_error "Docker não está instalado ou não está no PATH."
        exit 1
    fi

    if ! docker info &> /dev/null; then
        print_error "Docker não está rodando ou não há permissões para acessá-lo."
        exit 1
    fi

    print_success "Docker está instalado e funcionando corretamente."

# ----------------------------------------------------
#   SEÇÃO 5: PUSH DA IMAGEM
# ----------------------------------------------------

    print_docker "Iniciando push da imagem..."
    print_info "Tag: $FULL_TAG"

    docker push "$FULL_TAG" || {
        print_error "Falha ao fazer push da imagem. Verifique os logs acima."
        exit 1
    }

    print_success "Push concluído: $FULL_TAG"

    # Push da tag 'latest'
    if [[ "$PUSH_LATEST" == "true" ]]; then
        print_docker "Criando tag 'latest'..."
        docker tag "$FULL_TAG" "$LATEST_TAG"
        
        print_docker "Fazendo push da tag 'latest'..."
        docker push "$LATEST_TAG" || {
            print_error "Falha ao fazer push da tag 'latest'."
            exit 1
        }
        
        print_success "Push concluído: $LATEST_TAG"
    else
        print_warning "Push da tag 'latest' desabilitado."
    fi

    print_success "Processo finalizado com sucesso!"
