# API Service

## Available Scripts

### Development
- `npm start` - Starts the API server
- `npm run dev` - Starts the API server with hot-reload using nodemon
- `npm test` - Runs API tests
- `npm run health` - Checks if the API server is healthy and responding

### Docker Commands
- `npm run docker:build` - Builds the API container image
- `npm run docker:up` - Starts the API container in detached mode
- `npm run docker:down` - Stops and removes the API container
- `npm run docker:logs` - Shows and follows the API container logs

## Available Endpoints

### Health Checks
- `GET /health` - Basic health check
- `GET /health/timestamp` - Health check with timestamp

### Items API
- `GET /items` - List all items
- `GET /items/:id` - Get single item
- `POST /items` - Create new item
- `PUT /items/:id` - Update an item
- `DELETE /items/:id` - Delete an item
- `POST /reset` - Reset items to initial state

### JSONPlaceholder Integration
- `GET /jsonplaceholder/posts` - List all posts
- `GET /jsonplaceholder/posts/:id` - Get single post
- `POST /jsonplaceholder/posts` - Create new post
- `GET /jsonplaceholder/posts/:id/comments` - Get post comments

## Usage Example

```bash
# Start the API container
npm run docker:up

# Watch the logs
npm run docker:logs

# Rebuild after changes
npm run docker:build && npm run docker:up

# Test JSONPlaceholder integration
curl http://localhost/api/jsonplaceholder/posts
```

## Health Check

The health check endpoint (`/health`) returns a 200 OK status when the API is running properly.

```bash
# Check API health directly
npm run health

# Check API health in Docker container
curl -f http://localhost:5000/health

# Check API health through nginx proxy
curl -f http://localhost/api/health
```

The health check is also used in docker-compose.yml for container orchestration:
- Interval: 10s
- Timeout: 5s
- Retries: 3
- Start period: 5s