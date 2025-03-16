# docker-react-nginx README.md

# Docker Nginx React Demo

A demonstration of containerized React applications served through Nginx, showcasing modern web application architecture and Docker orchestration.

## Project Structure

```
docker-react-nginx
├── docker-compose.yml
├── nginx
│   ├── Dockerfile
│   └── nginx.conf
├── react-app-1
│   ├── Dockerfile
│   ├── src
│   │   ├── App.tsx
│   │   └── index.tsx
│   ├── package.json
│   └── README.md
├── react-app-2
│   ├── Dockerfile
│   ├── src
│   │   ├── App.tsx
│   │   └── index.tsx
│   ├── package.json
│   └── README.md
└── README.md
```

## Requirements

### Phase 1 - Basic Setup ✅
- Multiple React applications running in containers
- Nginx reverse proxy to route requests
- API service for backend functionality
- Docker Compose orchestration
- Basic development workflow

### Phase 2 - Enhanced Development Experience 🚧
- Hot reloading for React applications
- Improved development/production configuration
- Comprehensive test coverage
- CI/CD pipeline setup
- Development/Production environment parity

### Phase 3 - Production Readiness ⏳
- SSL/TLS configuration
- Performance optimization
- Monitoring and logging
- Load balancing
- High availability setup

## Architecture

### Current Architecture
```
                                  ┌─────────────────┐
                                  │                 │
                             ┌───▶│   React App 1   │
                             │    │   (/app1/*)     │
                             │    │                 │
┌──────────┐    ┌─────────┐  │    └─────────────────┘
│          │    │         │  │    ┌─────────────────┐
│ Browser  │───▶│  Nginx  │──┼───▶│   React App 2   │
│          │    │         │  │    │   (/app2/*)     │
└──────────┘    └─────────┘  │    └─────────────────┘
                             │    ┌─────────────────┐
                             └───▶│   API Service   │
                                  │   (/api/*)      │
                                  └─────────────────┘
```

### Key Components
1. **Nginx Server**: 
   - Routes requests to appropriate services
   - Handles static file serving
   - Manages caching headers
   
2. **React Applications**:
   - Two separate React apps
   - TypeScript support
   - Independent deployment capability
   
3. **API Service**:
   - Express.js backend
   - Health check endpoint
   - RESTful architecture

4. **Docker Infrastructure**:
   - Multi-container setup
   - Volume management
   - Network isolation

## Getting Started

### Prerequisites

- Docker
- Docker Compose

### Running the Project

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd docker-react-nginx
   ```

2. Build and run the containers:
   ```bash
   docker-compose up --build
   ```

3. Access the applications in your browser:
   - React App 1: `http://localhost/app1`
   - React App 2: `http://localhost/app2`

#### Development Environment
```bash
# Start development environment
docker compose -f docker-compose.dev.yml up --build

# Stop development environment
docker compose -f docker-compose.dev.yml down
```

#### Production Environment
```bash
# Start production environment (requires SSL certificates)
docker compose -f docker-compose.prod.yml up --build

# Stop production environment
docker compose -f docker-compose.prod.yml down
```

> Note: Before running production environment, ensure:
> 1. SSL certificates are in place
> 2. Domain is configured in nginx.prod.conf
> 3. Certificate paths are correctly set in docker-compose.prod.yml

#### Staging Environment
```bash
# Start staging environment
docker compose -f docker-compose.staging.yml up --build

# Stop staging environment
docker compose -f docker-compose.staging.yml down
```

> Note: Staging environment:
> - Runs on different ports (8080/8443)
> - Uses staging.your-domain.com subdomain
> - Includes staging-specific headers
> - Blocks search engine indexing
> - Matches production SSL setup

### Stopping the Project

To stop the running containers, use:
```bash
docker-compose down
```

## Available Scripts

### Root Level Scripts

These scripts should be run from the project root directory:

```bash
npm run docker:build     # Builds all Docker images
npm run docker:up        # Starts all containers in detached mode
npm run docker:down      # Stops and removes all containers and volumes
npm run docker:logs      # Shows and follows all container logs
npm run docker:restart   # Restarts all containers with a clean state
```

### API Scripts

Located in `/api`, these scripts manage the API container:

```bash
npm run docker:build     # Builds only the API container
npm run docker:up        # Starts only the API container
npm run docker:down      # Stops only the API container
npm run docker:logs      # Shows only API container logs
```

## Development Workflow

1. Start all services:
```bash
npm run docker:up
```

2. View logs:
```bash
npm run docker:logs
```

3. Rebuild after changes:
```bash
npm run docker:build && npm run docker:restart
```

## Current Status

### Completed ✅
- Basic container setup and orchestration
- Nginx routing configuration
- React applications boilerplate
- Basic API service
- Development workflow scripts

### In Progress 🚧
- Test coverage implementation
- Development environment optimization
- Documentation improvements
- Health check integration

### Planned ⏳
- Hot reload configuration
- CI/CD pipeline
- Production optimizations
- Monitoring setup

## Next Steps

### Short Term
1. API Service Enhancement
   - Add routes to connect to third-party REST API provider
   - Implement proxy middleware for API security
   - Add request/response logging
   - Create API documentation

2. React Application Development
   - Create new React app consuming the API service
   - Implement dynamic routing system
   - Add data visualization components
   - Setup state management

3. Infrastructure Improvements
   - Create template for new React apps
   - Automate Nginx configuration for new apps
   - Implement naming convention for routes
   - Add service discovery

### Medium Term
1. Database Integration
   - Add PostgreSQL container
   - Set up database migrations
   - Implement data models
   - Add backup/restore procedures

2. Deployment Setup
   - Use existing HTTPS domain and SSL certificates
   - Configure Nginx for SSL certificate paths
   - Set up reverse proxy on host server
   - Implement staging environment
   - Add deployment scripts
   ```bash
   # Example nginx SSL configuration to be added
   ssl_certificate /path/to/existing/fullchain.pem;
   ssl_certificate_key /path/to/existing/privkey.pem;
   ```

3. CI/CD Pipeline

### Long Term
1. Load balancing configuration
2. High availability setup
3. Performance optimization
4. Security hardening

## Adding a New React App

### Naming Convention
App names must:
- Start with a letter
- Contain only letters, numbers, or hyphens
- Be lowercase (recommended)
- Cannot start with "api" (reserved for API endpoints)
- Examples: 
  - ✅ `dashboard`, `user-profile`, `analytics-v2`
  - ❌ `api-dashboard` (starts with "api")
  - ❌ `123-app` (starts with number)
  - ❌ `My_App` (contains underscore)

### Technical Details
The nginx configuration reserves the `/api` path for backend services. Your app name will be used in URLs:
- Main app: `http://localhost/<app-name>/`
- Static files: `http://localhost/<app-name>/static/*`
- WebSocket: `http://localhost/<app-name>/ws`

### Steps to Add a New App
1. Create the app using Create React App with TypeScript:
```bash
npx create-react-app my-feature --template typescript
```

2. Add a Dockerfile in your app directory:
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

3. Add the service to `docker-compose.yml`:
```yaml
services:
  my-feature:
    build: 
      context: ./my-feature
      target: development
    volumes:
      - ./my-feature:/app
      - /app/node_modules
    ports:
      - "3000"
    environment:
      - REACT_APP_API_URL=/api
```

4. No nginx configuration needed! The generic configuration automatically handles:
- Main route: `http://localhost/my-feature/`
- Static files: `http://localhost/my-feature/static/*`
- WebSocket: `http://localhost/my-feature/ws`

5. Update your React app's package.json:
```json
{
  "name": "my-feature",
  "homepage": "/my-feature"
}
```

6. Start the services:
```bash
docker compose up --build
```

Your new app will be available at `http://localhost/my-feature/`

### Verification Steps
1. Check nginx configuration:
```bash
docker compose exec nginx nginx -t
```

2. Test the endpoints:
```bash
curl -I http://localhost/my-feature/
curl -I http://localhost/my-feature/static/css/main.css
```

3. Monitor logs:
```bash
docker compose logs -f my-feature
```

## Contributing

Please read our [CONTRIBUTING.md](./CONTRIBUTING.md) for details on our code of conduct, development workflow, and pull request process.

## License

This project is licensed under the MIT License.