#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

API_URL="http://localhost/api"
COMPOSE_FILE="../config/dev/docker-compose.yml"

# Check if containers are running and healthy
check_containers() {
    local running=0
    local containers=$(docker compose -f "$COMPOSE_FILE" ps --format json)
    if [ -n "$containers" ] && echo "$containers" | jq -e '.[] | select(.State=="running" and .Health=="healthy")' >/dev/null 2>&1; then
        running=1
    fi
    return $running
}

# Wait for service function
wait_for_service() {
    local service_name=$1
    local health_url=$2
    local expected_content=$3
    local max_attempts=30

    echo "Waiting for $service_name..."
    for i in $(seq 1 $max_attempts); do
        if curl -s "$health_url" | grep -q "$expected_content"; then
            echo -e "${GREEN}✓ $service_name is ready${NC}"
            return 0
        fi
        echo "Waiting... ($i/$max_attempts)"
        sleep 2
    done
    echo -e "${RED}✗ $service_name failed to start${NC}"
    return 1
}

# Verify all services are accessible
verify_services() {
    echo "Verifying services..."
    
    # Test API endpoints
    if ! wait_for_service "API" "$API_URL/health" "healthy"; then
        echo -e "${RED}✗ API health check failed${NC}"
        return 1
    fi
    
    # Test Counter app
    if ! wait_for_service "Test Counter" "http://localhost/test-counter/" "Test Counter"; then
        echo -e "${RED}✗ Test Counter app not accessible${NC}"
        docker compose -f "$COMPOSE_FILE" logs test-counter
        return 1
    fi
    
    # Test API Client app
    if ! wait_for_service "Test API Client" "http://localhost/test-api-client/" "Test API Client"; then
        echo -e "${RED}✗ Test API Client app not accessible${NC}"
        docker compose -f "$COMPOSE_FILE" logs test-api-client
        return 1
    fi
    
    echo -e "${GREEN}✓ All services verified${NC}"
    return 0
}

# Start containers function
start_containers() {
    echo "Ensuring clean environment..."
    stop_containers

    echo "Starting containers..."
    if ! docker compose -f "$COMPOSE_FILE" up -d --force-recreate; then
        echo -e "${RED}Error: Failed to start containers${NC}"
        return 1
    fi

    # Give containers time to initialize
    sleep 5

    echo "Verifying services..."
    if ! verify_services; then
        echo -e "${RED}Error: Service verification failed${NC}"
        echo "Container logs:"
        docker compose -f "$COMPOSE_FILE" logs
        return 1
    fi
}

# Stop containers function
stop_containers() {
    echo "Stopping containers..."
    if docker compose -f "$COMPOSE_FILE" ps --quiet 2>/dev/null | grep -q .; then
        docker compose -f "$COMPOSE_FILE" down
    else
        echo "No containers to stop"
    fi
}

# Array to store created item IDs
declare -a CREATED_ITEMS

# Function to wait for API to be ready
wait_for_api() {
    echo "Waiting for API to be ready..."
    for i in {1..30}; do
        echo "Checking API health..."
        local response=$(curl -s -w "\n%{http_code}" "$API_URL/health")
        local status_code=$(echo "$response" | tail -n1)
        local body=$(echo "$response" | sed \$d)
        
        if [ "$status_code" -eq 200 ]; then
            echo -e "${GREEN}API is ready${NC}"
            echo "Health check response: $body"
            return 0
        fi
        echo "Waiting... ($i/30) - Status: $status_code"
        echo "Docker container status:"
        docker compose -f "$COMPOSE_FILE" ps
        sleep 1
    done
    echo -e "${RED}Error: API failed to start${NC}"
    echo "Docker logs:"
    docker compose -f "$COMPOSE_FILE" logs api
    return 1
}

# Cleanup function
cleanup() {
    echo -e "\n${BOLD}Cleaning up test data...${NC}"
    for id in "${CREATED_ITEMS[@]}"; do
        if curl -s -X DELETE "$API_URL/items/$id" > /dev/null; then
            echo -e "${GREEN}✓ Cleaned up item $id${NC}"
        else
            echo -e "${YELLOW}⚠ Failed to clean up item $id${NC}"
        fi
    done
    
    echo -e "\n${BOLD}Shutting down containers...${NC}"
    stop_containers
}

# Register cleanup function
trap cleanup EXIT INT TERM

# Function to test endpoint
test_endpoint() {
    local method=$1
    local endpoint=$2
    local expected_status=$3
    local data=$4
    local description=$5
    
    echo -e "\n${BOLD}Testing: ${description:-$method $endpoint}${NC}"
    
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
    
    if [ "$status_code" -eq "$expected_status" ]; then
        echo -e "${GREEN}✓ Status: ${status_code} (Expected: ${expected_status})${NC}"
        echo -e "Response: $(echo "$body" | jq -C '.' 2>/dev/null || echo "$body")"
        return 0
    else
        echo -e "${RED}✗ Status: ${status_code} (Expected: ${expected_status})${NC}"
        echo "Response: $body"
        return 1
    fi
}

# Start containers and wait for API
echo -e "${BOLD}Setting up test environment...${NC}"
start_containers || exit 1
wait_for_api || { stop_containers; exit 1; }

echo -e "${BOLD}Resetting API data to initial state...${NC}"
curl -s -X POST "$API_URL/reset" > /dev/null

echo -e "${BOLD}API Endpoint Tests${NC}"
echo "===================="

# Health endpoints
test_endpoint "GET" "/health" 200 "" "Health check endpoint"
test_endpoint "GET" "/health/timestamp" 200 "" "Health check with timestamp"

# Items endpoints
test_endpoint "GET" "/items" 200 "" "Get all items"
test_endpoint "GET" "/items/1" 200 "" "Get item by ID"
test_endpoint "POST" "/items" 201 '{"name":"New Test Item"}' "Create new item"

# Error cases
test_endpoint "GET" "/items/999" 404 "" "Get non-existent item"
test_endpoint "GET" "/non-existent" 404 "" "Access non-existent endpoint"

echo -e "\n${GREEN}${BOLD}All tests passed successfully!${NC}"