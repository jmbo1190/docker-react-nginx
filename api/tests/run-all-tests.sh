#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

# Set paths
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPOSE_FILE="${PROJECT_ROOT}/config/dev/docker-compose.yml"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Export compose file path for child scripts
export COMPOSE_FILE

cd "${BASE_DIR}"

echo -e "${BOLD}Running all API tests${NC}"
echo "=========================="

# Verify docker-compose.yml exists
if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}Error: docker-compose.yml not found at ${COMPOSE_FILE}${NC}"
    exit 1
fi

# Run integrated tests (with nginx)
echo -e "\n${BOLD}1. Running integrated tests (with nginx)${NC}"
if ./api.test.sh; then
    echo -e "${GREEN}✓ Integrated tests passed${NC}"
else
    echo -e "${RED}✗ Integrated tests failed${NC}"
    exit 1
fi

# Run standalone tests (direct API)
echo -e "\n${BOLD}2. Running standalone tests${NC}"
if ./api.test.standalone.sh; then
    echo -e "${GREEN}✓ Standalone tests passed${NC}"
else
    echo -e "${RED}✗ Standalone tests failed${NC}"
    exit 1
fi

echo -e "\n${GREEN}${BOLD}All test suites passed successfully!${NC}"