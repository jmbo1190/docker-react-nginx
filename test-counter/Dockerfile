# Base stage for both development and production
FROM node:18-alpine AS base
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

