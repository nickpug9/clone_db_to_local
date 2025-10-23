#!/bin/bash

# LOAD ENV VARS
ENV_FILE=".env"
if [ -f "$ENV_FILE" ]; then
  export $(grep -v '^#' "$ENV_FILE" | xargs) # Filter out comments and load variables into current shell session
else
  echo "Missing .env file at $ENV_FILE"
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

# CREATE BACKUP FILE LOCATION
log "Creating tmp folder..."
mkdir -p "$TMP_BUCKET" || error_exit "Failed to create temp directory."
DUMP_FILE="$TMP_BUCKET/live_dump.sql"

# Export DB to tmp folder
log "Exporting live DB to $DUMP_FILE..."
ssh "$LIVE_SSH_USER" "mysqldump -u $LIVE_DB_USER -p$LIVE_DB_PASS $LIVE_DB_NAME" > "$DUMP_FILE" || error_exit "Failed to export database."


# Check if dump file exists and is not empty
if [ ! -s "$DUMP_FILE" ]; then
  error_exit "Database dump file is missing or empty."
fi

log "Database dump file created successfully."