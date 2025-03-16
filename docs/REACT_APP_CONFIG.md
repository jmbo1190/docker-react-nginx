# React App Configuration Guide

## Naming Conventions

### App Name Requirements

- Must start with a letter
- Can contain letters, numbers, and hyphens
- Must be lowercase (recommended)
- Cannot start with "api" (reserved for API endpoints)
- Examples:
  - ✅ `dashboard`
  - ✅ `user-profile`
  - ✅ `analytics-v2`
  - ❌ `api-dashboard` (starts with "api")
  - ❌ `123-app` (starts with number)
  - ❌ `My_App` (contains underscore)

### Technical Details

The nginx configuration uses this pattern to route requests:
```nginx
location ~ ^/(?!api)[a-zA-Z][a-zA-Z0-9-]*/ {
    # ...configuration
}
```

- `^/` - Path must start with slash
- `(?!api)` - Must not start with "api"
- `[a-zA-Z]` - Must start with a letter
- `[a-zA-Z0-9-]*` - Can be followed by letters, numbers, or hyphens
- `/` - Must end with slash

## URL Structure

Apps will be available at:
- Main app: `http://localhost/<app-name>/`
- Static files: `http://localhost/<app-name>/static/*`
- WebSocket: `http://localhost/<app-name>/ws`

## Configuration Steps

1. Update your React app's `package.json`:
```json
{
  "name": "<app-name>",
  "homepage": "/<app-name>"
}
```

2. Add to `docker-compose.yml`:
```yaml
services:
  <app-name>:
    build: 
      context: ./<app-name>
      target: development
    ports:
      - "3000"
```