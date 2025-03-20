# Nginx Configuration Documentation

## Overview

This document details the nginx configuration used in our multi-container React application setup with API proxying.

## Configuration Structure

### 1. Variable Mapping
```nginx
map $uri $react_app {
    ~^/(?<app_name>[a-zA-Z][a-zA-Z0-9-]*)/ $app_name;
    default "";
}
```
- Maps the URI to extract React app names dynamically
- Uses regex capture group for app name extraction
- Falls back to empty string if no match

### 2. Server Block Settings
```nginx
server {
    listen 80;
    server_name localhost;

    # Development settings
    client_max_body_size 100M;
    proxy_read_timeout 300;
    proxy_connect_timeout 300;
}
```

### 3. Location Blocks (in priority order)

#### 3.1 Health Check
```nginx
location = /api/health {
    proxy_pass http://api:5000/health;
    proxy_read_timeout 10s;
    proxy_connect_timeout 5s;
}
```
- Exact match for health check endpoint
- Short timeouts for quick failure detection

#### 3.2 API Endpoints
```nginx
location /api/ {
    proxy_pass http://api:5000/;
    proxy_intercept_errors on;
    
    # CORS headers included
    add_header 'Access-Control-Allow-Origin' '*' always;
    # ... other CORS headers
}
```
- Handles all API requests
- Strips /api/ prefix
- Includes CORS and error handling

#### 3.3 React App Static Files
```nginx
location ~ ^/(?!api)[a-zA-Z][a-zA-Z0-9-]*/static/.*$ {
    set $app_name $react_app;
    proxy_pass http://$app_name:3000;
}
```
- Matches static file requests for any React app
- Uses captured app name for dynamic proxying

#### 3.4 React App WebSocket Connections
```nginx
location ~ ^/(?!api)[a-zA-Z][a-zA-Z0-9-]*/ws$ {
    set $app_name $react_app;
    proxy_pass http://$app_name:3000/ws;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
}
```
- Handles WebSocket connections for React apps
- Includes necessary WebSocket headers

#### 3.5 React App Main Routes
```nginx
location ~ ^/(?!api)[a-zA-Z][a-zA-Z0-9-]*/ {
    set $app_name $react_app;
    proxy_pass http://$app_name:3000/;
}
```
- Catches all other React app routes
- Enables HTML5 history mode routing

#### 3.6 Root Redirect
```nginx
location = / {
    return 301 /test-counter/;
}
```
- Redirects root URL to default app

## Usage with Docker

This configuration is mounted in the nginx container:
```yaml
volumes:
  - ./config/dev/nginx/nginx.conf:/etc/nginx/conf.d/default.conf
```

## Location Block Priority

1. Exact matches (`=`)
   - `/api/health`
   - Root redirect
2. Regular expressions (`~` and `~*`)
   - Static files
   - WebSocket endpoints
   - React app routes
3. Prefix matches
   - API endpoints

## Debugging Tips

Added debug headers in API location:
```nginx
add_header X-Debug-Path $request_uri;
add_header X-Debug-Host $proxy_host;
```