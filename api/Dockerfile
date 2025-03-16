# Base stage
FROM node:18-alpine AS base
WORKDIR /usr/src/app
COPY package*.json ./
ENV PORT=5000

# Development stage
FROM base AS development

# Install curl and wget for healthchecks
RUN apk add --no-cache curl wget

# Install dependencies
RUN npm install

# Copy source code
COPY . .

# Add healthcheck
HEALTHCHECK --interval=10s --timeout=3s --start-period=10s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:$PORT/health || exit 1

EXPOSE $PORT

CMD ["npm", "run", "dev"]

# Production stage
FROM base AS production
RUN npm ci --only=production
COPY . .
EXPOSE $PORT
CMD ["npm", "start"]