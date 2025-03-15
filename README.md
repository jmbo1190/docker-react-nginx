# docker-react-nginx README.md

# Docker Nginx React Demo

This project demonstrates how to containerize multiple React applications and serve them using an Nginx server with Docker. The setup uses Docker Compose to manage the services, allowing for easy orchestration of the React apps and the Nginx server.

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

## Contributing

Feel free to submit issues or pull requests for improvements or bug fixes.

## License

This project is licensed under the MIT License.