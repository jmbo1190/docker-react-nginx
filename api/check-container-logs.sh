#!/bin/bash

# First, navigate to the project root
# e.g. cd ~/JSproj/docker-nginx-react-demo/docker-react-nginx
# Get the absolute path to the project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd $PROJECT_ROOT

# Check if any docker container is started
docker ps
# Or using docker compose
docker compose -f config/dev/docker-compose.yml ps

# Check the API container logs
docker logs dev-api-1

# Or using docker compose
docker compose -f config/dev/docker-compose.yml logs api

# Check the container health status
docker inspect dev-api-1 | jq '.[0].State.Health'
# Or using docker compose exposed port 5000 mapped to 5001
curl -v http://localhost:5001/health


# For real-time monitoring, follow the logs
docker compose -f config/dev/docker-compose.yml logs -f api

# To get more detailed container information
# docker inspect dev-api-1

# Check what's using port 5000
# sudo lsof -i :5000

# If needed:
# # Stop all containers
# docker compose -f config/dev/docker-compose.yml down

# # Clean up any previous containers/networks
# docker system prune -f

# # Remove old images
# docker image rm docker-react-nginx-api:latest

# # Rebuild and start API container
# docker compose -f config/dev/docker-compose.yml up -d --build api

# # Watch logs
# docker compose -f config/dev/docker-compose.yml logs -f api
