# README for React App 1

This is the README file for the first React application in the Dockerized setup with Nginx.

## Overview

This React application is part of a multi-container Docker setup that includes an Nginx server to serve static files. The application is built using React and can be run in a Docker container.

## Getting Started

To build and run this application, you can use Docker Compose. Make sure you have Docker and Docker Compose installed on your machine.

### Prerequisites

- Docker
- Docker Compose

### Building the Application

To build the Docker image for this React application, navigate to the root of the project and run:

```bash
docker-compose build react-app-1
```

### Running the Application

To run the application, use the following command:

```bash
docker-compose up
```

This will start the Nginx server and the React application in their respective containers.

### Accessing the Application

Once the containers are running, you can access the application by navigating to `http://localhost:3000` in your web browser.

## Scripts

The following scripts are available in the `package.json`:

- `start`: Starts the application in development mode.
- `build`: Builds the application for production.

## Contributing

If you would like to contribute to this project, please fork the repository and submit a pull request.

## License

This project is licensed under the MIT License. See the LICENSE file for details.