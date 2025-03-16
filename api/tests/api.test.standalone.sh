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
        response=$(curl -s -w "\n%{http_code}" -X POST \
            -H "Content-Type: application/json" \
            -d "${data}" \
            "$API_URL$endpoint")
    else
        response=$(curl -s -w "\n%{http_code}" "$API_URL$endpoint")
    fi
    
    local status_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | sed \$d)
    
    echo "Response (Status: $status_code):"
    echo "$body" | json_pp
    
    if [ "$status_code" -eq "$expected_status" ]; then
        echo -e "${GREEN}✓ $description succeeded${NC}"
        echo "$body"  # Return response body for further processing
        return 0
    else
        echo -e "${RED}✗ $description failed${NC}"
        return 1
    fi
}

# Test Cases
test_endpoint "GET" "/items" 200 "" "Get all items" || exit 1
test_endpoint "GET" "/items/1" 200 "" "Get item by ID" || exit 1

# Create new item and capture response
echo -e "\nTesting: Create new item"
create_response=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d '{"name":"Test Item"}' \
    "$API_URL/items")

echo "Create response:"
echo "$create_response" | json_pp

# Extract new item ID
new_item_id=$(echo "$create_response" | jq -r '.id')
if [ -z "$new_item_id" ] || [ "$new_item_id" = "null" ]; then
    echo -e "${RED}✗ Failed to get new item ID${NC}"
    exit 1
fi

# Verify new item
echo -e "\nTesting: Verify created item"
verify_response=$(curl -s -X GET "$API_URL/items/$new_item_id")
echo "Verify response:"
echo "$verify_response" | json_pp

if [ "$(echo "$verify_response" | jq -r '.name')" = "Test Item" ]; then
    echo -e "${GREEN}✓ New item verified${NC}"
else
    echo -e "${RED}✗ New item verification failed${NC}"
    exit 1
fi

echo -e "\n${GREEN}${BOLD}All tests passed successfully!${NC}"
