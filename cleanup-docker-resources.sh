# Remove unused containers, networks, images and volumes
docker system prune -af --volumes

# Clear node_modules volumes
docker volume ls -q | grep "node_modules" | xargs -r docker volume rm

# Stop here
exit 0


# Remove dangling images
docker image prune -af
# Remove unused volumes
docker volume prune -f
# Remove unused networks
docker network prune -f
# Remove unused containers
docker container prune -f
# Remove unused images
docker image prune -f
# Remove unused build cache
docker builder prune -f
# Remove unused objects
docker system prune -f
# Remove all stopped containers
docker container prune -f
# Remove all unused data
docker system prune -af