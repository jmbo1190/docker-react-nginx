#!/bin/bash
# filepath: docker-react-nginx/api/tests/api.test.sh
# Test the Express API endpoints using curl
# Note: This script uses the jq and json_pp commands to parse JSON responses
# Note: This script requires Docker Compose to be running the express-api container

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

API_URL="http://localhost/api"  # Using nginx proxy from docker-compose
COMPOSE_PROJECT="docker-react-nginx"

# Cleanup function
cleanup() {
    echo -e "\n=== Cleaning Up ==="
    docker-compose down 2>/dev/null
}

# Set trap for cleanup on script exit
trap cleanup EXIT

echo "=== Testing Pre-Requisites ==="

# Check for required tools
for tool in curl jq json_pp docker-compose; do
    if ! [ -x "$(command -v $tool)" ]; then
        echo -e "${RED}Error: $tool is not installed.${NC}"
        exit 1
    fi
done

echo "=== Setting Up Test Environment ==="

# Start the containers using docker-compose
echo "Starting containers..."
if ! docker-compose up -d; then
    echo -e "${RED}Error: Failed to start containers${NC}"
    exit 1
fi

# Wait for API to be ready
echo "Waiting for API to be ready..."
for i in {1..30}; do
    if curl -s "$API_URL/health" > /dev/null; then
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}Error: API failed to start${NC}"
        exit 1
    fi
    sleep 1
done

echo "=== Testing API Endpoints ==="

# Test GET all items
echo -e "\n1. Testing GET /api/items"
response=$(curl -s -X GET "$API_URL/api/items")
echo "$response" | json_pp
if [[ $(echo "$response" | jq length) -ge 2 ]]; then
    echo -e "${GREEN}✓ GET /api/items returned at least 2 items${NC}"
else
    echo -e "${RED}✗ GET /api/items failed${NC}"
    exit 1
fi

# Test GET single item
echo -e "\n2. Testing GET /api/items/1"
response=$(curl -s -X GET "$API_URL/api/items/1")
echo "$response" | json_pp
if [[ $(echo "$response" | jq -r '.id') == "1" ]]; then
    echo -e "${GREEN}✓ GET /api/items/1 returned correct item${NC}"
else
    echo -e "${RED}✗ GET /api/items/1 failed${NC}"
    exit 1
fi

# Test POST new item
echo -e "\n3. Testing POST /api/items"
response=$(curl -s -X POST "$API_URL/api/items" \
    -H "Content-Type: application/json" \
    -d '{"name": "Test Item"}')
echo "$response" | json_pp
if [[ $(echo "$response" | jq -r '.name') == "Test Item" ]]; then
    echo -e "${GREEN}✓ POST /api/items created new item${NC}"
else
    echo -e "${RED}✗ POST /api/items failed${NC}"
    exit 1
fi

# Verify new item in list
echo -e "\n4. Verifying new item in GET /api/items"
response=$(curl -s -X GET "$API_URL/api/items")
echo "$response" | json_pp
if [[ $(echo "$response" | jq 'map(select(.name == "Test Item")) | length') -eq 1 ]]; then
    echo -e "${GREEN}✓ New item found in list${NC}"
else
    echo -e "${RED}✗ New item not found in list${NC}"
    exit 1
fi

echo -e "\n${GREEN}All tests passed successfully!${NC}"
