# Base stage for both development and production
FROM node:18-alpine AS base

# Install health check tools
RUN apk add --no-cache curl wget

WORKDIR /app
COPY package*.json ./

# Development stage
FROM base AS development
RUN npm install
COPY . .
ENV PORT=3000
EXPOSE 3000
CMD ["npm", "start"]

# Build stage
FROM base AS builder
RUN npm ci
COPY . .
RUN npm run build

# Production stage
FROM alpine:latest AS production
WORKDIR /app
COPY --from=builder /app/build/ /app/build/
CMD ["tail", "-f", "/dev/null"]

# This Dockerfile uses a multi-stage build approach:
# 1. Base stage: Uses node:18-alpine to install dependencies
# 2. Development stage: Uses base stage to set up a development environment
# 3. Builder stage: Uses base stage to create the production build
# 4. Production stage: Uses alpine:latest to create a minimal image containing only the build output
#
# The build files in /app/build will be mounted as a volume by docker-compose.yml 
# at /usr/share/nginx/html/app1 in the nginx container
#
# Note: While using alpine makes the image smaller, we could alternatively 
# use nginx:alpine in the second stage if we wanted a self-contained deployable image (see Dockerfile.standalone):
#
# FROM nginx:alpine
# COPY --from=builder /app/build /usr/share/nginx/html

