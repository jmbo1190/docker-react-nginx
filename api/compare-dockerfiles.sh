#!/bin/bash
# filepath: docker-react-nginx/api/compare-dockerfiles.sh

echo "=== Building and Testing Images ==="
# Test Alpine
docker build -t express-api-alpine .
# Note: the --rm flag automatically removes the container after it exits
docker run --rm -it express-api-alpine node src/diagnose.js

# Test Full
docker build -t express-api-full -f Dockerfile.full .
# Note: the --rm flag automatically removes the container after it exits
docker run --rm -it express-api-full node src/diagnose.js

echo -e "\n=== Comparing Image Sizes ==="
docker images | grep express-api-

echo -e "\n=== Cleaning Up ==="
# Stop and remove any containers using these images
docker ps -a --filter "ancestor=express-api-full" -q | xargs -r docker rm -f
docker ps -a --filter "ancestor=express-api-alpine" -q | xargs -r docker rm -f

# Now remove the images (if needed)
docker rmi express-api-full
# docker rmi express-api-alpine


# HOWTO:
# Stop all containers:
#   docker stop $(docker ps -a -q)
#
# Remove all containers:
#   docker rm $(docker ps -a -q)
#
# Force remove specific images:
#   docker rmi -f api-full api-alpine
#
# Properly clean up in order:
# 1. First stop and remove containers
#   docker ps -a --filter "ancestor=express-api-full" -q | xargs -r docker stop
#   docker ps -a --filter "ancestor=express-api-full" -q | xargs -r docker rm
# 2. Then remove images (no -f needed)
#   docker rmi express-api-full