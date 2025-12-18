#!/bin/bash
#
# neovim.sh
# Configure Neovim
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${GREEN}==>${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_step() { echo ""; echo -e "${BLUE}[STEP]${NC} $1"; }
log_section() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$*${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Header
log_section "Setup Developer Environment & Containers"
sleep 1

# Install neovim
log_step "Installing Neovim and dependencies..."
apk add --update nodejs npm
apk add go
apk add lua-language-server
apk add vim neovim neovim-doc
log_info "Neovim and dependencies installed"

# Checkout dotfile config
log_step "Downloading dotfile config..."
if ! [ -d ".cfg" ]; then
  echo "alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'" >> $HOME/.bashrc
  echo ".cfg" >> .gitignore
  git clone --bare https://github.com/austinwalter/dotfiles.git $HOME/.cfg
  alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

  if [ -d ".config" ]; then
    mkdir -p .config-backup && \
    config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | \
    xargs -I{} mv {} .config-backup/{}
  fi

  config checkout
  config config --local status.showUntrackedFiles no
  log_info "Dotfile config downloaded"
fi

# Install Docker
log_step "Installing Docker..."
apk update && apk upgrade
apk add --no-cache docker openrc
addgroup ${USER} docker
rc-update add docker boot
service docker start
docker --version
rc-status
log_info "Docker installed"

# Setup Redis
# https://www.docker.com/blog/how-to-use-the-redis-docker-official-image
# https://redis.io/docs/latest/operate/oss_and_stack/install/install-stack/docker
log_step "Installing Redis..."
REDIS_NAME="redis-container"
if [ ! "$(docker ps -a | grep $REDIS_NAME)" ]; then
apk add redis
redis-cli -v
docker pull --quiet redis:alpine
docker run -d --name "$REDIS_NAME" -p 6379:6379 redis:alpine
# redis-cli -h 127.0.0.1 -p 6379 ping
fi
log_info "Redis installed and running"

# Setup Postgres
# https://www.docker.com/blog/how-to-use-the-postgres-docker-official-image
log_step "Installing Postgres..."
PG_NAME="pgcontainer"
PG_USER="postgres"
PG_PWD="pgpass"
apk add postgresql-client
psql -V
docker pull --quiet postgres:alpine
docker volume create pgdata
docker run --name "$PG_NAME" \
  --publish 5432:5432 \
  --env "POSTGRES_USER=postgres" \
  --env "POSTGRES_PASSWORD=$PG_PWD" \
  --volume "pgdata:/var/lib/docker/volumes/pgdata/_data" \
  --detach postgres:alpine
pg_isready -h localhost -p 5432 -U root -d postgres
log_info "Postgres installed and running"
