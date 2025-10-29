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

# CREATE BACKUP FILE LOCATION
log "Creating tmp folder..."
mkdir -p "$SCRIPT_DIR/$TMP_BUCKET" || error_exit "Failed to create temp directory."
DUMP_FILE="$SCRIPT_DIR/$TMP_BUCKET/$DUMP_FILE_NAME"

# Export DB to tmp folder
log "Exporting live DB to $DUMP_FILE..."
log "$LIVE_DB_HOST"
log "$LIVE_SSH_USER"
ssh $LIVE_SSH_USER "mysqldump --opt --user='$LIVE_DB_USER' -p'$LIVE_DB_PASS' --host='$LIVE_DB_HOST' --no-tablespaces '$LIVE_DB_NAME'" > "$DUMP_FILE" || error_exit "Failed to export database."

# Check if dump file exists and is not empty
if [ ! -s "$DUMP_FILE" ]; then
  error_exit "Database dump file is missing or empty."
fi

log "Database dump file created successfully."