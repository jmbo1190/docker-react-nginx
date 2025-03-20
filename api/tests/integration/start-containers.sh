#!/bin/bash

# Get the absolute path to the project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
COMPOSE_FILE="${PROJECT_ROOT}/config/dev/docker-compose.yml"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

# Verify compose file exists
if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}Error: docker-compose.yml not found at ${COMPOSE_FILE}${NC}"
    echo "Make sure you're running this from the api directory:"
    echo "cd api && npm test"
    exit 1
fi

echo "Starting containers..."
docker compose -f "$COMPOSE_FILE" up -d || exit 1

