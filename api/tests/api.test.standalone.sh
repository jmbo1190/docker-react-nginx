#!/bin/bash
# filepath: docker-react-nginx/api/tests/api.test.standalone.sh
# Test the Express API endpoints using curl
# Note: This script is standalone using docker run and does not require Docker Compose
# This script uses the jq and json_pp commands to parse JSON responses


# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

API_PORT=5000
CONTAINER_NAME=express-api-test
API_URL="http://localhost:${API_PORT}"

# Cleanup function
cleanup() {
    echo -e "\n=== Cleaning Up ==="
    docker rm -f $CONTAINER_NAME 2>/dev/null
}

# Set trap for cleanup on script exit
trap cleanup EXIT

echo "=== Testing Pre-Requisites ==="

# Check for curl
if ! [ -x "$(command -v curl)" ]; then
    echo -e "${RED}Error: curl is not installed.${NC}"
    exit 1
fi

# Check for jq
if ! [ -x "$(command -v jq)" ]; then
    echo -e "${RED}Error: jq is not installed.${NC}"
    exit 1
fi

# Check for Docker
if ! [ -x "$(command -v docker)" ]; then
    echo -e "${RED}Error: docker is not installed.${NC}"
    exit 1
fi

# Check for netcat
if ! [ -x "$(command -v nc)" ]; then
    echo -e "${RED}Error: netcat is not installed.${NC}"
    exit 1
fi

# Find an available port starting from API_PORT
find_available_port() {
    local port=$1
    while nc -z localhost $port 2>/dev/null; do
        port=$((port + 1))
    done
    echo $port
}

echo "=== Setting Up Test Environment ==="

# Clean up any existing container
docker rm -f $CONTAINER_NAME 2>/dev/null

# Find available port
API_PORT=$(find_available_port $API_PORT)
API_URL="http://localhost:${API_PORT}"
echo "Using port: $API_PORT"

# Build and start the container
echo "Building and starting API container..."
if ! docker build -t $CONTAINER_NAME ../.; then
    echo -e "${RED}Error: Failed to build container${NC}"
    exit 1
fi

if ! docker run -d --name $CONTAINER_NAME -p $API_PORT:5000 $CONTAINER_NAME; then
    echo -e "${RED}Error: Failed to start container${NC}"
    exit 1
fi

# Wait for container and API to be ready
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
