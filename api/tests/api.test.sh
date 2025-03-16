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
    docker compose -f ../config/dev/docker-compose.yml down
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
if ! docker compose -f ../config/dev/docker-compose.yml up -d; then
    echo -e "${RED}Error: Failed to start containers${NC}"
    exit 1
fi

# Wait for API to be ready
echo "Waiting for API to be ready..."
for i in {1..30}; do
    if curl -s "$API_URL/health" > /dev/null; then
        echo "API is ready"
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
echo "Calling: curl -s -X GET \"$API_URL/items\""
response=$(curl -s -v -X GET "$API_URL/items")
echo "Raw response:"
echo "$response"
echo "Formatted response:"
if echo "$response" | jq . >/dev/null 2>&1; then
    echo "$response" | json_pp
else
    echo "Invalid JSON received"
    echo "HTTP response headers:"
    curl -s -I "$API_URL/items"
    exit 1
fi

# Test GET single item
echo -e "\n2. Testing GET /api/items/1"
response=$(curl -s -X GET "$API_URL/items/1")
echo "Raw response:"
echo "$response"
echo "Formatted response:"
if echo "$response" | jq . >/dev/null 2>&1; then
    echo "$response" | json_pp
else
    echo "Invalid JSON received"
    echo "HTTP response headers:"
    curl -s -I "$API_URL/items/1"
    exit 1
fi

# Test POST new item
echo -e "\n3. Testing POST /api/items"
response=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d '{"name":"Test Item"}' \
    "$API_URL/items")
echo "Raw response:"
echo "$response"
echo "Formatted response:"
if echo "$response" | jq . >/dev/null 2>&1; then
    echo "$response" | json_pp
    if [[ $(echo "$response" | jq -r '.name') == "Test Item" ]]; then
        echo -e "${GREEN}✓ POST /api/items created new item${NC}"
    else
        echo -e "${RED}✗ POST /api/items failed - unexpected response${NC}"
        exit 1
    fi
else
    echo "Invalid JSON received"
    echo "HTTP response headers:"
    curl -s -I "$API_URL/items"
    exit 1
fi

# Verify new item in list
echo -e "\n4. Verifying new item in GET /api/items"
response=$(curl -s -X GET "$API_URL/items")  # Remove duplicate /api
if ! echo "$response" | jq . >/dev/null 2>&1; then
    echo "Invalid JSON received"
    echo "Raw response:"
    echo "$response"
    echo "HTTP response headers:"
    curl -s -I "$API_URL/items"
    exit 1
fi

echo "Response:"
echo "$response" | json_pp

if [[ $(echo "$response" | jq 'map(select(.name == "Test Item")) | length') -eq 1 ]]; then
    echo -e "${GREEN}✓ New item found in list${NC}"
else
    echo -e "${RED}✗ New item not found in list${NC}"
    exit 1
fi

echo -e "\n${GREEN}All tests passed successfully!${NC}"
