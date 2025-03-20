#!/bin/bash
# filepath: docker-react-nginx/api/tests/api.test.standalone.sh
# Test the Express API endpoints using curl
# Note: This script is standalone using docker run and does not require Docker Compose
# This script uses the jq and json_pp commands to parse JSON responses


# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

API_PORT=5001  # Changed to avoid conflict with integrated tests
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

# Test endpoint function for reusability
test_endpoint() {
    local method=$1
    local endpoint=$2
    local expected_status=$3
    local data=$4
    local description=$5
    
    echo -e "\nTesting: ${description:-$method $endpoint}"
    
    local response
    if [ "$method" == "POST" ]; then
        response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "${data}" \
            "$API_URL$endpoint")
        local status_code=$?
    else
        response=$(curl -s -X "$method" "$API_URL$endpoint")
        local status_code=$?
    fi
    
    echo "Response:"
    if ! echo "$response" | jq . >/dev/null 2>&1; then
        echo -e "${RED}Error: Invalid JSON response${NC}"
        echo "Raw response: $response"
        return 1
    fi

    echo "$response" | jq .
    return 0
}

# Test Cases
echo "=== Testing API Endpoints ==="

# Test GET all items
echo -e "\nTesting GET /items"
response=$(curl -s -X GET "$API_URL/items")
if ! echo "$response" | jq . >/dev/null 2>&1; then
    echo -e "${RED}Error: Invalid JSON response${NC}"
    echo "Raw response: $response"
    exit 1
fi

items_count=$(echo "$response" | jq '. | length')
if [ "$items_count" -lt 2 ]; then
    echo -e "${RED}✗ Expected at least 2 items, got $items_count${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Got $items_count items${NC}"

# Test GET single item
echo -e "\nTesting GET /items/1"
response=$(curl -s -X GET "$API_URL/items/1")
if ! echo "$response" | jq -e '.id == 1' >/dev/null; then
    echo -e "${RED}✗ Failed to get item 1${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Successfully retrieved item 1${NC}"

# Test POST new item
echo -e "\nTesting POST /items"
response=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d '{"name":"Test Item"}' \
    "$API_URL/items")

if ! echo "$response" | jq -e '.name == "Test Item"' >/dev/null; then
    echo -e "${RED}✗ Failed to create new item${NC}"
    exit 1
fi

new_item_id=$(echo "$response" | jq '.id')
echo -e "${GREEN}✓ Created new item with ID $new_item_id${NC}"

# Verify new item exists
echo -e "\nVerifying new item"
response=$(curl -s -X GET "$API_URL/items/$new_item_id")
if ! echo "$response" | jq -e '.name == "Test Item"' >/dev/null; then
    echo -e "${RED}✗ Failed to verify new item${NC}"
    exit 1
fi
echo -e "${GREEN}✓ New item verified${NC}"

echo -e "\n${GREEN}${BOLD}All tests passed successfully!${NC}"
