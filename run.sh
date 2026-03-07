#!/bin/bash
#
# ==============================================================================
# SCRIPT: run.sh
# DESCRIÇÃO: Script interativo para simplificar a inicialização do ambiente
#            TOTVS-Protheus-in-Docker. Guia o usuário na escolha do banco
#            de dados e do perfil de execução.
# AUTOR: Julian de Almeida Santos
# DATA: 2025-10-12
# USO: ./run.sh
# ==============================================================================

# Carregar versões centralizadas
if [ -f "versions.env" ]; then
    source "versions.env"
elif [ -f "../versions.env" ]; then
    source "../versions.env"
fi

readonly DOCKER_TAG="${DOCKER_USER}/${POSTGRES_IMAGE_NAME}:${POSTGRES_VERSION}"

docker run --rm \
    --name "${POSTGRES_IMAGE_NAME}" \
    -p 5432:5432 \
    -e "POSTGRES_USER=postgres" \
    -e "POSTGRES_PASSWORD=${DATABASE_PASSWORD:-ProtheusDatabasePassword1}" \
    "${DOCKER_TAG}"
