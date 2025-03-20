# Contributing Guidelines

Thank you for considering contributing to the Docker Nginx React Demo project! This document outlines the standards and processes we follow.

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Follow the project's technical standards
- Help others learn and grow

## Getting Started

1. Fork the repository at `https://github.com/jmbo1190/docker-react-nginx`
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR-USERNAME/docker-react-nginx.git
   ```
   (Replace YOUR-USERNAME with your GitHub username)
3. Create a new branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Workflow

### 1. Environment Setup

```bash
# Install dependencies for all applications
cd react-app-1 && npm install
cd ../react-app-2 && npm install
cd ../api && npm install
```

### 2. Making Changes

- Follow the existing code style and conventions
- Write clean, maintainable, and testable code
- Include comments for complex logic
- Update documentation as needed

### 3. Testing

- Add unit tests for new features
- Ensure all existing tests pass
- Test your changes in both development and production modes

### 4. Commit Guidelines

Follow conventional commits format:

```
type(scope): description

[optional body]

[optional footer]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Adding or modifying tests
- `chore`: Maintenance tasks

### 5. Pull Request Process

1. Update your fork with the latest changes from main:
   ```bash
   git remote add upstream https://github.com/ORIGINAL-OWNER/docker-react-nginx.git
   git fetch upstream
   git merge upstream/main
   ```

2. Push your changes:
   ```bash
   git push origin feature/your-feature-name
   ```

3. Create a pull request with:
   - Clear title and description
   - Reference to related issues
   - List of changes made
   - Screenshots (if applicable)

## Code Standards

### TypeScript/JavaScript
- Use TypeScript for new components
- Follow ESLint configuration
- Use async/await for asynchronous operations
- Implement proper error handling

### Docker
- Keep images minimal
- Use multi-stage builds
- Follow security best practices
- Document environment variables

### Testing
- Write unit tests for new features
- Maintain >80% code coverage
- Include integration tests for API endpoints
- Test Docker configurations

## Review Process

1. All PRs require at least one review
2. Reviewers should provide feedback within 48 hours
3. Address all review comments
4. Maintain a civil and professional discourse

## Questions?

- Open an issue for feature discussions
- Use PR comments for code-related questions
- Check existing issues and documentation first

## License

By contributing, you agree that your contributions will be licensed under the MIT License.