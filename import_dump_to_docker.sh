#!/bin/bash

# LOAD ENV VARS
ENV_FILE=".env"
if [ -f "$ENV_FILE" ]; then
  export $(grep -v '^#' "$ENV_FILE" | xargs) # Filter out comments and load variables into current shell session
else
  log "Missing .env file at $ENV_FILE"
  exit 1
fi

# FUNCTIONS
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

error_exit() {
    log "ERROR: $1"
    exit 1
}

# Define dump file path
LIVE_DUMP_FILE="$TMP_BUCKET/live_dump.sql"

# Check if file exists
if [ ! -s "$LIVE_DUMP_FILE" ]; then
  error_exit "Dump file missing or empty: $LIVE_DUMP_FILE"
fi

# Optional: Reset local DB
log "Resetting local DB..."
docker exec -it "$LOCAL_CONTAINER_NAME" wp db reset --yes --allow-root

# Import dump
log "Importing dump into Docker DB..."
docker exec -i "$LOCAL_CONTAINER_NAME" mysql -u root -p"$MYSQL_PASSWORD"
 "$LOCAL_DB_NAME" < "$LIVE_DUMP_FILE"
 
if [ $? -eq 0 ]; then
  log "✅ Import successful."
else
  log "❌ Import failed."
fi


# Replace URLs
log "Running search-replace..."
docker exec -it "$LOCAL_CONTAINER_NAME" wp search-replace "$LIVE_URL" "$LOCAL_URL" --allow-root

if [ $? -eq 0 ]; then
  log "✅ search-replace successful."
else
  log "❌ search-replace failed."
fi

