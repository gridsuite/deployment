#!/bin/bash

# Set databases path
GRIDSUITE_DATABASES=$(realpath "DATABASES")
export GRIDSUITE_DATABASES

# Assuming the Docker Compose file is relative to the script's execution path
cd docker-compose/explicit-profiles || { echo "Failed to change directory. Check if the path is correct. Exiting."; exit 1; }
docker compose --profile suite stop || { echo "Docker Compose failed to stop. Exiting."; exit 1; }