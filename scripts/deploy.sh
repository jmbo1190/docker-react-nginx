#!/bin/bash

ENV=${1:-dev}
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="$BASE_DIR/config/$ENV"

# Validate environment
if [[ ! -d "$CONFIG_DIR" ]]; then
    echo "Invalid environment: $ENV"
    echo "Usage: ./deploy.sh [dev|staging|prod]"
    exit 1
fi

# Load environment variables
if [[ -f "$CONFIG_DIR/.env" ]]; then
    set -a
    source "$CONFIG_DIR/.env"
    set +a
fi

# Run docker-compose with environment-specific config
cd "$BASE_DIR"
docker compose -f "$CONFIG_DIR/docker-compose.yml" up --build -d

echo "Deployed $ENV environment"
