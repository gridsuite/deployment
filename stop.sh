# Assuming the Docker Compose file is relative to the script's execution path
cd docker-compose/explicit-profiles || { echo "Failed to change directory. Check if the path is correct. Exiting."; exit 1; }
docker compose --profile study stop || { echo "Docker Compose failed to stop. Exiting."; exit 1; }