#!/bin/bash

# LOAD ENV VARS
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

ENV_FILE="$SCRIPT_DIR/.env"
if [ -f "$ENV_FILE" ]; then
  export $(grep -v '^#' "$ENV_FILE" | xargs) # Filter out comments and load variables into current shell session
else
  echo "Missing .env file at $ENV_FILE"
  exit 1
fi

# FUNCTIONS
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$SCRIPT_DIR/$LOG_FILE"
}

error_exit() {
    log "ERROR: $1"
    exit 1
}

# Check for .sql
DUMP_FILE="$SCRIPT_DIR/$TMP_BUCKET/$DUMP_FILE_NAME"
if [ ! -s "$DUMP_FILE" ]; then
  error_exit "SQL file missing or empty: $DUMP_FILE"
fi

# Create Dockerfile
log "Creating docker-compose.yml"
cat <<EOF > docker-compose.yml
version: '3.8'

services:
  wordpress:
    image: wordpress:latest
    ports:
      - "8080:80"
    environment:
      WORDPRESS_DB_HOST: "db"
      WORDPRESS_DB_NAME: "${LIVE_DB_NAME}"
      WORDPRESS_DB_USER: "${WORDPRESS_DB_USER}"
      WORDPRESS_DB_PASSWORD: "${WORDPRESS_DB_PASSWORD}"
    volumes:
      - wordpress_data:/var/www/html
    depends_on:
      - db

  db:
    image: "${MYSQL_IMAGE}"
    environment:
      MYSQL_DATABASE: "${LIVE_DB_NAME}"
      MYSQL_USER: "${WORDPRESS_DB_USER}"
      MYSQL_PASSWORD: "${WORDPRESS_DB_PASSWORD}"
      MYSQL_ROOT_PASSWORD: "${WORDPRESS_DB_ROOT_PASSWORD}"
    volumes:
      - db_data:/var/lib/mysql
      - "${DUMP_FILE}:/docker-entrypoint-initdb.d/init.sql"

  phpmyadmin:
    image: phpmyadmin/phpmyadmin
    ports:
      - "8081:80"
    environment:
      PMA_HOST: db
      MYSQL_ROOT_PASSWORD: "${WORDPRESS_DB_ROOT_PASSWORD}"
    depends_on:
      - db

volumes:
  wordpress_data:
  db_data:
EOF

# Start Docker containers
log "Starting Docker containers..."
docker-compose down -v
docker-compose up -d
if [ $? -eq 0 ]; then
  log "✅ Docker environment initialized successfully."
else
  log "❌ Docker initialization failed."
fi
