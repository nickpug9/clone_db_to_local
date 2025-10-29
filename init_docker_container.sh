#!/bin/bash

# LOAD ENV VARS
ENV_FILE=".env"
if [ -f "$ENV_FILE" ]; then
  export $(grep -v '^#' "$ENV_FILE" | xargs) # Filter out comments and load variables into current shell session
else
  echo "Missing .env file at $ENV_FILE"
  exit 1
fi

# Create Docker volume if it doesn't exist
if ! docker volume ls | grep -q $MYSQL_VOLUME; then
  echo "Creating Docker volume '$MYSQL_VOLUME'..."
  docker volume create $MYSQL_VOLUME
fi

# Check if container already exists
if [ "$(docker ps -a -q -f name=$CONTAINER_NAME)" ]; then
  echo "Container '$CONTAINER_NAME' already exists. Starting it..."
  docker start $CONTAINER_NAME
else
  echo "Creating new MySQL container '$CONTAINER_NAME' with persistent volume..."
  docker run -d \
    --name $CONTAINER_NAME \
    -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD \
    -e MYSQL_DATABASE=$MYSQL_DATABASE \
    -e MYSQL_USER=$MYSQL_USER \
    -e MYSQL_PASSWORD=$MYSQL_PASSWORD \
    -v $MYSQL_VOLUME:/var/lib/mysql \
    -p 3306:3306 \
    $MYSQL_IMAGE
fi
``