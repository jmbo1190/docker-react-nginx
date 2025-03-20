#!/bin/bash

# Add OS detection at the start of the script
OS_TYPE="$(uname -s)"

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

# API access configuration
API_MODE="proxy"  # or "direct" for debugging
case "$API_MODE" in
    "proxy")
        API_BASE_URL="http://localhost"
        API_PATH_PREFIX="/api"  # Double api prefix for proxy mode
        ;;
    "direct")
        API_BASE_URL="http://localhost:5001"
        API_PATH_PREFIX=""      # Single api prefix for direct mode
        ;;
    *)
        echo "Invalid API_MODE: $API_MODE"
        exit 1
        ;;
esac

# Update build_api_url function to handle URLs correctly
build_api_url() {
    local endpoint="$1"
    
    # Remove leading slashes
    endpoint="${endpoint#/}"
    
    # Special case for health endpoint
    if [[ "$endpoint" == "health"* ]]; then
        # Direct connection to health endpoint
        # echo "${API_BASE_URL}${API_PATH_PREFIX#/api}/health"
        echo "${API_BASE_URL}${API_PATH_PREFIX}/health"
        return
    fi
    
    # For all other API endpoints
    echo "${API_BASE_URL}${API_PATH_PREFIX}/${endpoint}"
}

# Cleanup function
cleanup_called=false

cleanup() {
    if [ "$cleanup_called" = true ]; then
        return
    fi
    cleanup_called=true
    
    echo "=== Final Cleanup ==="
    echo "Stopping containers..."
    docker compose -f "$COMPOSE_FILE" down
    docker system prune -f > /dev/null 2>&1
    echo "Cleanup complete"
}

# Set trap for cleanup on script exit or error
trap cleanup EXIT ERR

# Function to check API health
check_api_health() {
    local response
    local status_code
    local body
    local health_endpoint="$(build_api_url '/health')"

    response=$(curl -s -w "\n%{http_code}" --connect-timeout 5 --max-time 10 "$health_endpoint")
    status_code=$?

    if [ $status_code -eq 0 ]; then
        # Parse response
        status_code=$(echo "$response" | tail -n1)
        body=$(echo "$response" | sed \$d)
        
        if [ "$status_code" = "200" ]; then
            echo -e "${GREEN}API is ready (via $health_endpoint)${NC}"
            echo "Health check response: $body"
            return 0
        fi
    fi

    # Show detailed status for debugging
    echo "API not ready"
    echo "Direct API status:"
    curl -v "$(build_api_url '/health')" 2>&1 || true
    echo "Nginx proxy status:"
    curl -v "$(build_api_url '/health')" 2>&1 || true
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

# Add after the initial container startup

echo "=== Diagnostic Information ==="
echo "1. Container Status:"
docker compose -f "$COMPOSE_FILE" ps

echo -e "\n2. API Container Logs:"
docker compose -f "$COMPOSE_FILE" logs api

echo -e "\n3. Health Check Details:"
docker inspect dev-api-1 | jq '.[0].State.Health'

# Replace direct port access with nginx-proxied endpoint
echo -e "\n4. Testing API Health Endpoint:"
curl -v "$(build_api_url '/health')"

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

# Initialize test counters
tests_total=0
tests_passed=0

# Helper function for test results - Move this before any test calls
test_result() {
    local name="$1"
    local status="$2"
    tests_total=$((tests_total + 1))
    if [ $status -eq 0 ]; then
        tests_passed=$((tests_passed + 1))
        echo -e "${GREEN}✓ $name${NC}"
    else
        echo -e "${RED}✗ $name${NC}"
    fi
}

# Update make_api_request function to properly handle and validate responses
make_api_request() {
    local method="$1"
    local endpoint="$2"
    local data="$3"
    local description="$4"
    
    echo -e "\n${BOLD}$description${NC}"
    
    # Create temporary files
    local response_file=$(mktemp)
    local http_code_file=$(mktemp)
    local debug_file=$(mktemp)
    
    # Debug: Show request details
    echo "Making $method request to: $(build_api_url "$endpoint")"
    [ -n "$data" ] && echo "Request body: $data"
    
    # Make request with headers in debug output
    if [ -n "$data" ]; then
        curl -v -X "$method" \
            -H "Content-Type: application/json" \
            -H "Accept: application/json" \
            -d "$data" \
            -o "$response_file" \
            -D "$debug_file" \
            -w '%{http_code}' \
            "$(build_api_url "$endpoint")" > "$http_code_file" 2>>"$debug_file"
    else
        curl -v -X "$method" \
            -H "Accept: application/json" \
            -o "$response_file" \
            -D "$debug_file" \
            -w '%{http_code}' \
            "$(build_api_url "$endpoint")" > "$http_code_file" 2>>"$debug_file"
    fi
    
    # Read status code and response
    local http_code=$(<"$http_code_file")
    local response=$(<"$response_file")
    
    echo -e "\nResponse Status Code: $http_code"
    echo "Response Headers:"
    cat "$debug_file"
    echo -e "\nResponse Body:"
    echo "----------------------------------------"
    
    # Format and validate JSON response
    if [ -n "$response" ]; then
        # Try to pretty print with jq
        if formatted_json=$(echo "$response" | jq . 2>/dev/null); then
            echo "$formatted_json"
            local formatted_response="$response"
        else
            echo "Raw response (invalid JSON):"
            echo "$response"
            echo -e "\nDebug info:"
            echo "Response length: ${#response} bytes"
            echo "First 1000 bytes:"
            echo "${response:0:1000}"
            formatted_response=""
        fi
    else
        echo "<empty response>"
        formatted_response=""
    fi
    
    echo "----------------------------------------"
    
    # Cleanup
    rm -f "$response_file" "$http_code_file" "$debug_file"
    
    # Return success only if we got a 2xx status and valid JSON
    if [[ $http_code =~ ^2[0-9][0-9]$ ]] && [ -n "$formatted_response" ]; then
        printf "%s" "$formatted_response"
        return 0
    else
        echo -e "\n${RED}ERROR: Request failed (Status: $http_code)${NC}"
        return 1
    fi
}

# Test cases in order of API routes
echo -e "\n${BOLD}Testing API Endpoints${NC}"
echo "===================="

test_health_endpoints() {
    echo "Testing health endpoints..."
    response=$(make_api_request "GET" "/health" "" "Health check")
    test_result "GET /api/health" $?

    response=$(make_api_request "GET" "/health/timestamp" "" "Health check with timestamp")
    test_result "GET /api/health/timestamp" $?
}

test_reset_data() {
    echo "Testing data reset..."
    response=$(make_api_request "POST" "/api/reset" "" "Resetting API data")
    test_result "POST /api/reset" $?
}

test_items_endpoints() {
    echo "Testing items endpoints..."
    # GET all items
    response=$(make_api_request "GET" "/api/items" "" "Getting all items")
    test_result "GET /api/items" $?

    # GET single item
    response=$(make_api_request "GET" "/api/items/1" "" "Getting single item")
    test_result "GET /api/items/1" $?

    # POST new item
    response=$(make_api_request "POST" "/api/items" '{"name":"Test Item"}' "Creating new item")
    test_result "POST /api/items" $?

    # Verify item creation
    response=$(make_api_request "GET" "/api/items" "" "Getting updated item list")
    echo "Response for item creation verification: $response"  # Add this line for debugging
    if [ $? -eq 0 ]; then
        echo "Raw response: $response"  # Add this line to print the raw response
        if echo "$response" | grep -q '"name":"Test Item"'; then
            test_result "Verify item creation" 0
        else
            test_result "Verify item creation" 1
        fi
    else
        test_result "Verify item creation" 1
    fi

    # DELETE item
    response=$(make_api_request "DELETE" "/api/items/1" "" "Deleting an item")
    test_result "DELETE /api/items/1" $?

    # Verify deletion
    response=$(make_api_request "GET" "/api/items/1" "" "Getting deleted item")
    if [ $? -ne 0 ]; then
        test_result "Verify item deletion" 0
    else
        test_result "Verify item deletion" 1
    fi
}

test_error_cases() {
    echo "Testing error cases..."
    response=$(make_api_request "GET" "/items/999" "" "Getting non-existent item")
    if [ $? -ne 0 ]; then
        test_result "404 for non-existent item" 0
    else
        test_result "404 for non-existent item" 1
    fi

    response=$(make_api_request "POST" "/items" '{"invalid":"data"}' "Creating invalid item")
    if [ $? -ne 0 ]; then
        test_result "400 for invalid item data" 0
    else
        test_result "400 for invalid item data" 1
    fi
}

test_jsonplaceholder_endpoints() {
    echo "Testing JsonPlaceholder endpoints..."
    
    # GET all posts
    echo "Testing GET /api/jsonplaceholder/posts..."
    echo "Request URL: $(build_api_url "/jsonplaceholder/posts")"
    echo "Response content:"
    test_jsonplaceholder_endpoints() {
        echo "Testing JsonPlaceholder endpoints..."
        local response_file=$(mktemp)
        local status
        
        # Test GET all posts
        echo "Testing GET /api/jsonplaceholder/posts..."
        curl -s "$(build_api_url "/jsonplaceholder/posts")" > "$response_file"
        status=$?
        
        if [ $status -eq 0 ] && [ -s "$response_file" ]; then
            # Validate posts array has correct structure
            if jq -e 'length > 0 and .[0] | has("userId", "id", "title", "body")' "$response_file" > /dev/null; then
                test_result "GET /api/jsonplaceholder/posts" 0
            else
                echo "Invalid posts response format"
                test_result "GET /api/jsonplaceholder/posts" 1
            fi
        else
            test_result "GET /api/jsonplaceholder/posts" 1
        fi
        
        # Test GET single post
        echo "Testing GET /api/jsonplaceholder/posts/1..."
        curl -s "$(build_api_url "/jsonplaceholder/posts/1")" > "$response_file"
        status=$?
        
        if [ $status -eq 0 ] && [ -s "$response_file" ]; then
            # Validate single post structure
            if jq -e 'has("userId", "id", "title", "body") and .id == 1' "$response_file" > /dev/null; then
                test_result "GET /api/jsonplaceholder/posts/1" 0
            else
                echo "Invalid single post response"
                test_result "GET /api/jsonplaceholder/posts/1" 1
            fi
        else
            test_result "GET /api/jsonplaceholder/posts/1" 1
        fi
        
        # Test POST new post
        echo "Testing POST /api/jsonplaceholder/posts..."
        local test_data='{"title":"test post","body":"test body","userId":1}'
        curl -s -X POST -H "Content-Type: application/json" \
             -d "$test_data" \
             "$(build_api_url "/jsonplaceholder/posts")" > "$response_file"
        status=$?
        
        if [ $status -eq 0 ] && [ -s "$response_file" ]; then
            # Validate created post
            if jq -e 'has("id") and .title == "test post"' "$response_file" > /dev/null; then
                test_result "POST /api/jsonplaceholder/posts" 0
            else
                echo "Invalid created post response"
                test_result "POST /api/jsonplaceholder/posts" 1
            fi
        else
            test_result "POST /api/jsonplaceholder/posts" 1
        fi
        
        # Test GET post comments
        echo "Testing GET /api/jsonplaceholder/posts/1/comments..."
        curl -s "$(build_api_url "/jsonplaceholder/posts/1/comments")" > "$response_file"
        status=$?
        
        if [ $status -eq 0 ] && [ -s "$response_file" ]; then
            # Validate comments array
            if jq -e 'length > 0 and .[0] | has("postId", "id", "name", "email", "body")' "$response_file" > /dev/null; then
                test_result "GET /api/jsonplaceholder/posts/1/comments" 0
            else
                echo "Invalid comments response"
                test_result "GET /api/jsonplaceholder/posts/1/comments" 1
            fi
        else
            test_result "GET /api/jsonplaceholder/posts/1/comments" 1
        fi
        
        # Test filtering posts by userId
        echo "Testing GET /api/jsonplaceholder/posts?userId=1..."
        curl -s "$(build_api_url "/jsonplaceholder/posts?userId=1")" > "$response_file"
        status=$?
        
        if [ $status -eq 0 ] && [ -s "$response_file" ]; then
            # Validate filtered posts
            if jq -e 'length > 0 and all(.userId == 1)' "$response_file" > /dev/null; then
                test_result "GET /api/jsonplaceholder/posts?userId=1" 0
            else
                echo "Invalid filtered posts response"
                test_result "GET /api/jsonplaceholder/posts?userId=1" 1
            fi
        else
            test_result "GET /api/jsonplaceholder/posts?userId=1" 1
        fi

        # Cleanup
        rm -f "$response_file"
    }
    local response_content=$(curl -s "$(build_api_url "/jsonplaceholder/posts/1/comments")")
    local status=$?
    echo "Response status: $status"
    echo "Response body:"
    echo "$response_content" | jq '.'
}

# Main test execution
test_health_endpoints
test_reset_data
test_items_endpoints
test_error_cases
test_jsonplaceholder_endpoints

# Print final test summary
echo -e "\n${BOLD}Test Summary${NC}"
echo "===================="
echo -e "Total tests: $tests_total"
echo -e "Passed: ${GREEN}$tests_passed${NC}"
echo -e "Failed: ${RED}$((tests_total - tests_passed))${NC}"

# Let the cleanup happen through the trap
