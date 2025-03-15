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

## Usage Example

```bash
# Start the API container
npm run docker:up

# Watch the logs
npm run docker:logs

# Rebuild after changes
npm run docker:build && npm run docker:up
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