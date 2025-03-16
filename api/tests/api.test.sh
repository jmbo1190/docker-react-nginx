#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Use COMPOSE_FILE from parent script or set default
COMPOSE_FILE=${COMPOSE_FILE:-"../../config/dev/docker-compose.yml"}
API_URL="http://localhost/api"

# Verify compose file exists
if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}Error: docker-compose.yml not found at ${COMPOSE_FILE}${NC}"
    exit 1
fi

# Cleanup function
cleanup() {
    echo -e "\n=== Cleaning Up ==="
    # Stop and remove containers
    docker compose -f "$COMPOSE_FILE" down -v

    # Remove dangling volumes
    docker volume prune -f

    # Remove unused node_modules volumes
    docker volume ls -q | grep "node_modules" | xargs -r docker volume rm
}

# Set trap for cleanup on script exit or error
trap cleanup EXIT ERR

# Function to check API health
check_api_health() {
    local response
    local status_code
    local body

    # Try both direct API and nginx-proxied endpoints
    local endpoints=(
        "http://localhost:5001/health"  # Direct API port
        "http://localhost/api/health"   # Through nginx
    )

    for endpoint in "${endpoints[@]}"; do
        response=$(curl -s -w "\n%{http_code}" --connect-timeout 5 --max-time 10 "$endpoint")
        status_code=$?

        if [ $status_code -eq 0 ]; then
            # Parse response
            status_code=$(echo "$response" | tail -n1)
            body=$(echo "$response" | sed \$d)
            
            if [ "$status_code" = "200" ]; then
                echo -e "${GREEN}API is ready (via $endpoint)${NC}"
                echo "Health check response: $body"
                return 0
            fi
        fi
    done

    # Show detailed status for debugging
    echo "API not ready"
    echo "Direct API status:"
    curl -v "http://localhost:5001/health" 2>&1 || true
    echo "Nginx proxy status:"
    curl -v "http://localhost/api/health" 2>&1 || true
    echo "Container status:"
    docker compose -f "$COMPOSE_FILE" ps
    return 1
}

# Function to check nginx readiness
check_nginx_health() {
    local max_attempts=30
    local attempt=1
    
    echo "Checking nginx readiness..."
    while [ $attempt -le $max_attempts ]; do
        if curl -s -o /dev/null "http://localhost/"; then
            echo -e "${GREEN}Nginx is ready${NC}"
            return 0
        fi
        echo "Waiting for nginx (attempt $attempt/$max_attempts)..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo -e "${RED}Nginx failed to become ready${NC}"
    docker compose -f "$COMPOSE_FILE" logs nginx
    return 1
}

# Function to validate nginx configuration
validate_nginx_config() {
    echo "Validating nginx configuration..."
    
    # Run nginx -t in the nginx container
    if ! docker compose -f "$COMPOSE_FILE" exec -T nginx nginx -t 2>&1; then
        echo -e "${RED}✗ Nginx configuration test failed${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓ Nginx configuration is valid${NC}"
    return 0
}

# Wait for containers to be ready with better status output
wait_for_containers() {
    echo "Waiting for containers to be ready..."
    for i in {1..30}; do
        # Show container status
        echo "Container status (attempt $i/30):"
        docker compose -f "$COMPOSE_FILE" ps
        
        # First check if API is healthy
        if docker compose -f "$COMPOSE_FILE" ps api | grep -q "(healthy)"; then
            # Then check if nginx can accept connections
            if check_nginx_health; then
                # Finally check if React apps are ready
                if docker compose -f "$COMPOSE_FILE" ps test-api-client | grep -q "(healthy)" && \
                   docker compose -f "$COMPOSE_FILE" ps test-counter | grep -q "(healthy)"; then
                    echo -e "${GREEN}All containers are ready${NC}"
                    return 0
                fi
            fi
        fi
        
        sleep 2
    done
    
    echo -e "${RED}Error: Containers failed to become healthy${NC}"
    docker compose -f "$COMPOSE_FILE" logs
    return 1
}

echo "=== Testing Pre-Requisites ==="

# Check for required tools
for tool in curl jq json_pp docker; do
    if ! [ -x "$(command -v $tool)" ]; then
        echo -e "${RED}Error: $tool is not installed.${NC}"
        exit 1
    fi
done

# Start containers for nginx validation
echo "Starting containers for nginx validation..."
docker compose -f "$COMPOSE_FILE" up -d nginx || exit 1

# Validate nginx configuration
if ! validate_nginx_config; then
    echo -e "${RED}Error: Invalid nginx configuration${NC}"
    docker compose -f "$COMPOSE_FILE" down
    exit 1
fi

echo "=== Setting Up Test Environment ==="

# Start and wait for containers
echo "Starting containers..."
docker compose -f "$COMPOSE_FILE" up -d || exit 1

if ! wait_for_containers; then
    echo -e "${RED}Error: Containers failed to start properly${NC}"
    docker compose -f "$COMPOSE_FILE" logs
    exit 1
fi

# Wait for API to be ready
echo "Waiting for API to be ready..."
MAX_RETRIES=30
RETRY_INTERVAL=2

for i in $(seq 1 $MAX_RETRIES); do
    if check_api_health; then
        break
    fi
    
    if [ $i -eq $MAX_RETRIES ]; then
        echo -e "${RED}Error: API failed to start after $((MAX_RETRIES * RETRY_INTERVAL)) seconds${NC}"
        docker compose -f "$COMPOSE_FILE" logs api
        exit 1
    fi
    
    echo "Attempt $i of $MAX_RETRIES - Waiting ${RETRY_INTERVAL}s..."
    sleep $RETRY_INTERVAL
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
