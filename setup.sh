#!/bin/bash

# Function to download a file if it does not exist
download_file() {
  local url=$1
  local target_path=$2

  # Check if the file already exists to avoid re-downloading
  if [ ! -f "$target_path" ]; then
    echo "Downloading $(basename "$target_path")..."
    curl -s -L "$url" -o "$target_path" || { echo "Failed to download $(basename "$target_path"). Exiting."; exit 1; }
  else
    echo "$(basename "$target_path") already exists. Skipping download."
  fi
}

# Check if ENV exists or if new given in commandline parameter, if not, ask user for a path (relative or absolute)
if [ -z "$1" ] && [ -n "$GRIDSUITE_DATABASES" ]; then
  echo "Using GRIDSUITE_DATABASES from environment: $GRIDSUITE_DATABASES"
else
  if [ -n "$1" ]; then
    # Convert to absolute path and create path structure
    GRIDSUITE_DATABASES=$(realpath "$1")
    export GRIDSUITE_DATABASES
  else
    if [ -z "$GRIDSUITE_DATABASES" ]; then
      echo "Enter the root directory location for GRIDSUITE_DATABASES:"
      read USER_INPUT
      GRIDSUITE_DATABASES=$(realpath "$USER_INPUT")
      export GRIDSUITE_DATABASES
    fi
  fi
fi

if [ -z "$GRIDSUITE_DATABASES" ]; then
  echo "GRIDSUITE_DATABASES is not set. Exiting."
  exit 1
fi

# Create the subdirectories with the required file mode
mkdir -p "$GRIDSUITE_DATABASES/cases" "$GRIDSUITE_DATABASES/postgres" "$GRIDSUITE_DATABASES/elasticsearch" "$GRIDSUITE_DATABASES/init" || { echo "Failed to create directories. Exiting."; exit 1; }

# Change the file mode to 777 for all subdirectories
chmod 777 "$GRIDSUITE_DATABASES/cases" "$GRIDSUITE_DATABASES/postgres" "$GRIDSUITE_DATABASES/elasticsearch" "$GRIDSUITE_DATABASES/init" || { echo "Failed to set permissions. Exiting."; exit 1; }

echo "Folder structure created under $GRIDSUITE_DATABASES with required permissions."

# Populate init folder
download_file "https://raw.githubusercontent.com/gridsuite/geo-data/main/src/test/resources/geo_data_substations.json" "$GRIDSUITE_DATABASES/init/geo_data_substations.json"
download_file "https://raw.githubusercontent.com/gridsuite/geo-data/main/src/test/resources/geo_data_lines.json" "$GRIDSUITE_DATABASES/init/geo_data_lines.json"
download_file "https://raw.githubusercontent.com/gridsuite/cgmes-boundary-server/main/src/test/resources/business_processes.json" "$GRIDSUITE_DATABASES/init/business_processes.json"
download_file "https://raw.githubusercontent.com/gridsuite/cgmes-boundary-server/main/src/test/resources/tsos.json" "$GRIDSUITE_DATABASES/init/tsos.json"

echo "Configuration files downloaded."

# Assuming the Docker Compose file is relative to the script's execution path
cd docker-compose/explicit-profiles || { echo "Failed to change directory. Check if the path is correct. Exiting."; exit 1; }
docker compose --profile study up -d || { echo "Docker Compose failed to start. Check Docker setup. Exiting."; exit 1; }
