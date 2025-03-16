#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}Running all API tests${NC}"
echo "=========================="

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