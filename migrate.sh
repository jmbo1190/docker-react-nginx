#!/bin/bash

# Create base directories
mkdir -p config/{dev,staging,prod}/{nginx,api,react-app-1,react-app-2}

# Move environment-specific files
mv docker-compose.dev.yml config/dev/docker-compose.yml
mv docker-compose.staging.yml config/staging/docker-compose.yml
mv docker-compose.prod.yml config/prod/docker-compose.yml

# Move nginx configs
mv nginx/nginx.dev.conf config/dev/nginx/nginx.conf
mv nginx/nginx.staging.conf config/staging/nginx/nginx.conf
mv nginx/nginx.prod.conf config/prod/nginx/nginx.conf

# Move environment files
mv .env config/dev/.env
mv .env.staging config/staging/.env
cp config/staging/.env config/prod/.env  # Create prod env from staging

# Update the deploy script
cat > scripts/deploy.sh << 'EOF'
#!/bin/bash

ENV=${1:-dev}
CONFIG_DIR="config/$ENV"

# Validate environment
if [[ ! -d "$CONFIG_DIR" ]]; then
    echo "Invalid environment: $ENV"
    echo "Usage: ./deploy.sh [dev|staging|prod]"
    exit 1
fi

# Load environment variables
if [[ -f "$CONFIG_DIR/.env" ]]; then
    export $(cat "$CONFIG_DIR/.env" | xargs)
fi

# Run docker-compose with environment-specific config
docker compose -f "$CONFIG_DIR/docker-compose.yml" up --build -d

echo "Deployed $ENV environment"
EOF

chmod +x scripts/deploy.sh