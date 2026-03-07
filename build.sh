#!/bin/bash
#
# ==============================================================================
# SCRIPT: build.sh
# DESCRIÇÃO: Responsável por realizar o build da imagem Docker para o PostgreSQL 
#            com TOTVS Protheus.
# AUTOR: Julian de Almeida Santos
# DATA: 2025-10-12
# USO: ./build.sh [OPTIONS]
#
# OPÇÕES:
#   --progress=<MODE>           Define o modo de progresso (auto|plain|tty) [padrão: auto]
#   --no-cache                  Desabilita o cache do Docker
#   --build-arg KEY=VALUE       Passa argumentos adicionais para o Docker build
#   --tag=<TAG>                 Define uma tag customizada para a imagem
#   -h, --help                  Exibe esta mensagem de ajuda
#
# EXEMPLOS:
#   ./build.sh
#   ./build.sh --progress=plain --no-cache
#   DOCKER_BUILD_ARGS="--build-arg VAR1=val1 --build-arg VAR2=val2" ./build.sh
# ==============================================================================

# --- Configuração de Robustez (Boas Práticas Bash) ---
# -e: Sai imediatamente se um comando falhar.
# -u: Trata variáveis não definidas como erro.
# -o pipefail: Garante que um pipeline (ex: cat | tar) falhe se qualquer comando falhar.
set -euo pipefail

# ----------------------------------------------------
#   SEÇÃO 1: DEFINIÇÃO DE FUNÇÕES AUXILIARES
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

    print_progress() {
        local message="$1"
        echo "🚀 $message"
    }

    print_verify() {
        local message="$1"
        echo "🔍 $message"
    }

    print_docker() {
        local message="$1"
        echo "🐳 $message"
    }

    show_help() {
        cat << EOF
USO: ./build.sh [OPTIONS]

OPÇÕES:
  --progress=<MODE>           Define o modo de progresso (auto|plain|tty) [padrão: auto]
  --no-cache                  Desabilita o cache do Docker
  --build-arg KEY=VALUE       Passa argumentos adicionais para o Docker build
  --tag=<TAG>                 Define uma tag customizada para a imagem
  -h, --help                  Exibe esta mensagem de ajuda

EXEMPLOS:
  ./build.sh
  ./build.sh --progress=plain --no-cache
  DOCKER_BUILD_ARGS="--build-arg VAR1=val1 --build-arg VAR2=val2" ./build.sh

EOF
        exit 0
    }

    check_versions() {
        if [ -f "versions.env" ]; then
            # shellcheck source=versions.env
            source "versions.env"
            print_info "Versões carregadas do 'versions.env':"
        else
            print_error "Arquivo 'versions.env' não encontrado."
            exit 1
        fi
    }

    check_file() {
        local file_path=$1
        if [ ! -f "$file_path" ]; then
            print_error "Arquivo '$file_path' não encontrado."
            exit 1
        fi
    }


    check_dir() {
        local dir_path=$1
        if [ ! -d "$dir_path" ]; then
            print_error "Diretório '$dir_path' não encontrado."
            exit 1
        fi
    }

# ----------------------------------------------------
#   SEÇÃO 2: PARSE DE ARGUMENTOS
# ----------------------------------------------------

    DOCKER_PROGRESS="auto"
    DOCKER_NO_CACHE=""
    CUSTOM_TAG=""
    BUILD_ARGS=()

    while [[ $# -gt 0 ]]; do
        case $1 in
            --progress=*)
                DOCKER_PROGRESS="${1#*=}"
                shift
                ;;
            --no-cache)
                DOCKER_NO_CACHE="--no-cache"
                shift
                ;;
            --build-arg)
                BUILD_ARGS+=("--build-arg" "$2")
                shift 2
                ;;
            --build-arg=*)
                BUILD_ARGS+=("--build-arg" "${1#*=}")
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
#   SEÇÃO 3: DEFINIÇÕES VARIÁVEIS
# ----------------------------------------------------

    check_versions

    # Detecta se está usando imagem base customizada
    USING_CUSTOM_BASE=false
    if [[ "${GITHUB_ACTIONS:-false}" == "true" ]] && [[ -n "${IMAGE_BASE:-}" ]]; then
        USING_CUSTOM_BASE=true
        print_info "Imagem base customizada detectada: ${IMAGE_BASE}"
    fi

    POSTGRES_BACKUP_DIR="./packages"
    POSTGRES_BACKUP_FILES=(
        "${POSTGRES_BACKUP_DIR}/data.tar.gz"
    )

    # Define o diretório atual
    CURRENT_PATH=$(dirname -- "$0")
    if ! cd "$CURRENT_PATH" &> /dev/null; then
        print_error "Não foi possível acessar o diretório '$CURRENT_PATH'."
    fi

    # Define a tag final
    if [[ -n "$CUSTOM_TAG" ]]; then
        DOCKER_TAG="$CUSTOM_TAG"
    else
        DOCKER_TAG="${DOCKER_USER}/${POSTGRES_IMAGE_NAME}:${POSTGRES_VERSION}"
    fi

    # Adiciona build args de variável de ambiente se existir
    if [[ -n "${DOCKER_BUILD_ARGS:-}" ]]; then
        BUILD_ARGS+=("$DOCKER_BUILD_ARGS")
    fi

# ----------------------------------------------------
#   SEÇÃO 4: PREPARAÇÃO DOS RECURSOS
# ----------------------------------------------------

    print_verify "Verificando se o Docker está instalado e funcionando..."

        if ! command -v docker &> /dev/null; then
            print_error "Docker não está instalado ou não está no PATH."
            exit 1
        fi

        if ! docker info &> /dev/null; then
            print_error "Docker não está rodando ou não há permissões para acessá-lo."
            exit 1
        fi

        print_success " * Docker está instalado e funcionando corretamente."

    # ----------------------------------------------------------------------

    print_verify "Verificando se o arquivo Dockerfile existe..."

        check_file "Dockerfile"

        print_success " * Arquivo 'Dockerfile' encontrado."

    print_verify "Verificando o arquivo em packages/..."

        for file in "${POSTGRES_BACKUP_FILES[@]}"; do
            if [ ! -f "$file" ]; then
                # Cria um arquivo tar vazio se não existir para evitar erro no COPY do Dockerfile
                tar -czf "$file" -T /dev/null
                # Pula validação de recursos se estiver usando imagem base customizada
                if [[ "$USING_CUSTOM_BASE" == "true" ]]; then
                    print_info "Usando imagem base customizada - pulando validação de recursos locais"
                else
                    print_info "Backup '$file' não encontrado; ele será desconsiderado na inicialização do contêiner."
                fi
            fi
        done

# ----------------------------------------------------
#   SEÇÃO 5: EXECUÇÃO DO DOCKER BUILD
# ----------------------------------------------------

    print_docker "Iniciando Docker build..."
    print_info "Tag: $DOCKER_TAG"
    print_info "Progress: $DOCKER_PROGRESS"
    print_info "Cache: $([ -n "$DOCKER_NO_CACHE" ] && echo "Desabilitado" || echo "Habilitado")"
    [[ ${#BUILD_ARGS[@]} -gt 0 ]] && print_info "Build Args: ${BUILD_ARGS[*]}"

    # Detecta se está rodando no GitHub Actions e adiciona IMAGE_BASE
    if [[ "$USING_CUSTOM_BASE" == "true" ]]; then
        BUILD_ARGS+=("--build-arg" "IMAGE_BASE=${IMAGE_BASE}")
        print_info "Usando IMAGE_BASE: ${IMAGE_BASE}"
    fi

    docker build \
        ${BUILD_ARGS[@]+"${BUILD_ARGS[@]}"} \
        $DOCKER_NO_CACHE \
        --progress="$DOCKER_PROGRESS" \
        -t "$DOCKER_TAG" . || {
            print_error "Falha no Docker build. Verifique os logs acima."
            exit 1
        }

    print_success "Docker build finalizado com sucesso!"
    print_success "Imagem: $DOCKER_TAG"
