# Dockerização do PostgreSQL para ERP TOTVS Protheus

## Overview

Este diretório contém a implementação do container Docker para o banco de dados **PostgreSQL**, configurado e otimizado para o ERP TOTVS Protheus.

A imagem utiliza uma estratégia de **pré-carregamento de dados**, onde o banco de dados já vem com a estrutura de dicionários do Protheus inicializada através de snapshots do diretório `PGDATA`. Isso elimina a necessidade de rodar assistentes de criação de tabelas que podem levar horas.


### Outros Componentes Necessários

*   **appserver**: O servidor de aplicação Protheus.
*   **dbaccess**: Middleware de acesso ao banco.
*   **licenseserver**: O serviço de gerenciamento de licenças.

## Início Rápido

**Importante:** Este contêiner precisa estar na mesma rede Docker que os outros serviços para que a comunicação funcione.

1.  **Baixe a imagem (se disponível no Docker Hub):**
    ```bash
    docker pull juliansantosinfo/totvs_postgres:latest
    ```

2.  **Crie a rede Docker (caso ainda não exista):**
    ```bash
    docker network create totvs
    ```

3.  **Execute o contêiner:**
    ```bash
    docker run -d \
      --name totvs_postgres \
      --network totvs \
      -p 5432:5432 \
      -e "POSTGRES_USER=postgres" \
      -e "POSTGRES_PASSWORD=ProtheusDatabasePassword1" \
      juliansantosinfo/totvs_postgres:latest
    ```

## Build Local

Caso queira construir a imagem localmente:

### 1. Preparar Pacotes

Caso queira utilizar um backup do banco de dados, coloque os arquivos de dados (snapshots físicos) compactados em um arquivo chamado `data.tar.gz` no diretório `packages/`.

O arquivo compactado deve manter a estrutura de diretórios `/var/lib/postgresql/data`:

```txt
packages/
└── data.tar.gz
```

**Arquivos necessários:**
- **Backup do Banco** - `data.tar.gz` (contendo a estrutura `/var/lib/postgresql/data/`)


### 2. Executar Build

Execute o script de build:

```bash
./build.sh
```

### Opções de Build

O script `build.sh` suporta várias opções:

```bash
./build.sh [OPTIONS]
```

**Opções disponíveis:**
- `--progress=<MODE>` - Define o modo de progresso (auto|plain|tty) [padrão: auto]
- `--no-cache` - Desabilita o cache do Docker
- `--build-arg KEY=VALUE` - Passa argumentos adicionais para o Docker build
- `--tag=<TAG>` - Define uma tag customizada para a imagem
- `-h, --help` - Exibe ajuda

**Exemplos:**
```bash
# Build padrão
./build.sh

# Build sem cache com progresso detalhado
./build.sh --progress=plain --no-cache

# Build com imagem base customizada
./build.sh --build-arg IMAGE_BASE=custom:tag

# Build com tag customizada
./build.sh --tag=myuser/totvs_oracle:1.0
```

### Build com Imagem Base Customizada

Quando usando uma imagem base customizada que já contém os recursos do Protheus (via `IMAGE_BASE` no `versions.env`), o script automaticamente pula a validação de diretórios locais:

```bash
# No GitHub Actions, IMAGE_BASE é carregado automaticamente
# Para build local com imagem customizada:
export IMAGE_BASE=juliansantosinfo/imagebase:totvs-oracle-build_21.3.0
./build.sh
```

## Push para Registry

Para enviar a imagem para o Docker Hub:

```bash
./push.sh [OPTIONS]
```

**Opções disponíveis:**
- `--no-latest` - Não faz push da tag 'latest'
- `--tag=<TAG>` - Define uma tag customizada para push
- `-h, --help` - Exibe ajuda

**Comportamento:**
- A tag `latest` só é enviada quando em branches `main` ou `master`
- Em outras branches, apenas a tag versionada é enviada

**Exemplos:**
```bash
# Push padrão (versão + latest se em main/master)
./push.sh

# Push apenas da versão (sem latest)
./push.sh --no-latest

# Push de tag customizada
./push.sh --tag=myuser/totvs_oracle:custom
```

## CI/CD com GitHub Actions

O projeto inclui workflow automatizado em `.github/workflows/deploy.yml` que:

1. **Detecta mudanças relevantes** - Ignora alterações em documentação e configurações
2. **Carrega imagem base customizada** - Usa `IMAGE_BASE` do `versions.env`
3. **Build automatizado** - Executa `./build.sh` com detecção de ambiente
4. **Push condicional** - Envia `latest` apenas em branches principais

**Configuração necessária:**

Adicione os secrets no repositório GitHub:
- `DOCKER_USERNAME` - Usuário do Docker Hub
- `DOCKER_TOKEN` - Token de acesso do Docker Hub

**Triggers:**
- Push em branches: `master`, `main`, `24.*`, `25.*`
- Pull requests para essas branches
- Execução manual via `workflow_dispatch`

## Persistência de Dados
Os dados do banco residem no diretório `/var/lib/postgresql/data` dentro do container. É altamente recomendável mapear este diretório para um volume Docker para garantir a persistência dos dados entre reinícios de container.

No Compose, o volume padrão é o `totvs_postgres_data`.

## Variáveis de Ambiente

| Variável | Descrição | Valor Padrão |
|---|---|---|
| `POSTGRES_USER` | Define o nome do superusuário do banco de dados. | `postgres` |
| `POSTGRES_PASSWORD` | Define a senha para o superusuário. | `ProtheusDatabasePassword1` |
| `POSTGRES_DB` | Nome do banco de dados a ser criado na inicialização. | `protheus` |
| `RESTORE_BACKUP` | Define se o backup inicial deve ser restaurado (`Y`/`N`). | `Y` |
| `DEBUG_SCRIPT` | Ativa o modo de depuração dos scripts (`true`/`false`). | `false` |
| `TZ` | Fuso horário do contêiner. | `America/Sao_Paulo` |
