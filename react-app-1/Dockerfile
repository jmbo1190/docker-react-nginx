# Build stage - compile the React application
FROM node:18 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Use a lightweight image to store build output
FROM alpine:latest
WORKDIR /app
COPY --from=builder /app/build/ /app/build/

# Keep container running
CMD ["tail", "-f", "/dev/null"]

# This Dockerfile uses a multi-stage build approach:
# 1. Builder stage: Uses node:18 to install dependencies and create the production build
# 2. Final stage: Uses nginx:alpine to create a minimal image containing only the build output
#
# The build files in /app/build will be mounted as a volume by docker-compose.yml 
# at /usr/share/nginx/html/app1 in the nginx container
#
# Note: While using alpine makes the image smaller, we could alternatively 
# use nginx:alpine in the second stage if we wanted a self-contained deployable image (see Dockerfile.standalone):
#
# FROM nginx:alpine
# COPY --from=builder /app/build /usr/share/nginx/html

