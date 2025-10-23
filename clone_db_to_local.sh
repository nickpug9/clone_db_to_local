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


# Run export
log "[INFO] Running export-db.sh..."
bash ./export-db.sh || error_exit "Export failed."

# Run import
log "[INFO] Running import-db.sh..."
bash ./import-db.sh || error_exit "Import failed."


