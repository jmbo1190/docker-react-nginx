# Nginx Configuration

This configuration file handles routing and serving of the API and React applications.

## Structure

```nginx
server {
    listen 80;  # HTTP port
}
```

## Security Headers

The following security headers are added to all responses:
- `X-Frame-Options: SAMEORIGIN` - Prevents clickjacking attacks
- `X-XSS-Protection: 1; mode=block` - Enables browser XSS filtering
- `X-Content-Type-Options: nosniff` - Prevents MIME type sniffing

## API Configuration

The `/api/` location block proxies requests to the API service:
```nginx
location /api/ {
    proxy_pass http://api:5000/api/;
}
```
- Maintains the `/api` prefix when forwarding requests
- Sets standard proxy headers for proper request handling
- Enables keep-alive connections

## React Applications

### Common Features for Both Apps
- Served from `/app1/` and `/app2/` paths
- Files served from `/usr/share/nginx/html/{app1|app2}/`
- HTML5 history mode support via `try_files`
- Different caching strategies for static vs HTML files

### Static Files (JS, CSS, Images)
```nginx
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
    expires 1y;
    add_header Cache-Control "public, no-transform";
}
```
- One year cache expiration
- Public caching enabled
- Prevents transformation by proxies

### HTML Files
```nginx
location ~* \.html$ {
    expires -1;
    add_header Cache-Control 'no-store, no-cache, must-revalidate';
}
```
- No caching
- Forces revalidation
- Ensures latest content is served

## HTML5 History Mode

React's router uses HTML5 History API for client-side routing. The `try_files` directive in nginx handles this by:

```nginx
location /app1/ {
    try_files $uri $uri/ /app1/index.html;
}
```

### How it works

1. When a request comes in (e.g., `/app1/users/123`):
   - First tries exact URI match (`$uri`)
   - Then tries directory match (`$uri/`)
   - Finally falls back to `/app1/index.html`

2. This enables:
   - Direct URL access (e.g., `http://localhost/app1/users/123`)
   - Browser refresh on any route
   - Bookmarking of React routes

### Example Routes

```
http://localhost/app1/users        → serves /app1/index.html
http://localhost/app1/users/123    → serves /app1/index.html
http://localhost/app1/static/x.js  → serves the actual JS file
```

Without `try_files`, direct access to routes would result in 404 errors because these URLs exist only in the React application's routing system, not as actual files on the server.

## Default Routing

```nginx
location = / {
    return 301 /app1/;
}
```
Redirects root URL (`/`) to the first React application (`/app1/`)

## Usage with Docker

This configuration is used in the nginx container and mounted as:
```yaml
volumes:
  - ./nginx.conf:/etc/nginx/conf.d/default.conf
```

## Location Directive Syntax

Nginx uses location blocks to determine how to process requests based on their URI. The basic syntax is:

```nginx
location [modifier] pattern { ... }
```

### Modifiers Used in Our Config

1. **`^~` (Preferential Prefix)**
```nginx
location ^~ /app1/ { ... }
```
- Used for React app locations
- Takes precedence over regex matches
- Matches beginning of URI
- Stops nginx from checking other regex locations

2. **`~*` (Case-insensitive Regex)
```nginx
location ~* \.(js|css|png)$ { ... }
```
- Used for static file matching
- Matches file extensions case-insensitively
- Allows complex pattern matching

3. **`=` (Exact Match)**
```nginx
location = / { ... }
```
- Used for root URL redirect
- Matches the URI exactly
- Highest priority match type

### Priority Order

Nginx processes location blocks in this order:
1. Exact match (`=`)
2. Preferential prefix (`^~`)
3. Regular expressions (`~*` and `~`) in order of appearance
4. Basic prefix (no modifier)

### Examples from Our Config

```nginx
# Root redirect (exact match)
location = / {
    return 301 /app1/;
}

# React app routes (preferential prefix)
location ^~ /app1/ {
    alias /usr/share/nginx/html/app1/;
    try_files $uri $uri/ /app1/index.html;
}

# Static files (case-insensitive regex)
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
    expires 1y;
}
```

This hierarchy ensures that:
- Root URL redirects work immediately
- React app routes take precedence over regex matches
- Static file handling applies consistently across all paths