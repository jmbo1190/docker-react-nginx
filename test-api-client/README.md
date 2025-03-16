# File: /docker-react-nginx/docker-react-nginx/react-app-2/README.md

# React App 2

This is the second React application in the Dockerized setup with Nginx.

## Getting Started

To get a copy of this project up and running on your local machine for development and testing purposes, follow these steps.

### Prerequisites

- Docker
- Docker Compose

### Building the Docker Image

To build the Docker image for this React application, run the following command in the root of the project:

```bash
docker build -t react-app-2 ./react-app-2
```

### Running the Application

To run the application, you can use Docker Compose. Make sure you are in the root directory of the project and run:

```bash
docker-compose up
```

This will start the application along with the Nginx server.

### Accessing the Application

Once the application is running, you can access it in your web browser at:

```
http://localhost:3000
```

### Built With

- [React](https://reactjs.org/) - The web framework used
- [Docker](https://www.docker.com/) - Containerization platform
- [Nginx](https://www.nginx.com/) - Web server for serving static files

### Contributing

If you wish to contribute to this project, please fork the repository and create a pull request.

### License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.