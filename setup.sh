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

# Set databases path
GRIDSUITE_DATABASES=$(realpath "DATABASES")
export GRIDSUITE_DATABASES

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

# Update IP
# Capture the first IP address into a variable
target_ip=$(hostname -I | awk '{print $1}')

# Use the variable as needed
echo "The target IP address is: $target_ip"

# Loop through all files in the directory
for file in "docker-compose/explicit-profiles"/*; do
  # Check if file exists to avoid errors with sed command when no files match
  if [ -f "$file" ]; then
    # Use sed to replace 'localhost' and '172.17.0.1' with 'target_ip' in-place
    sed -i "s/localhost/$target_ip/g" "$file"
    sed -i "s/172.17.0.1/$target_ip/g" "$file"
  fi
done

# Assuming the Docker Compose file is relative to the script's execution path
cd docker-compose/explicit-profiles || { echo "Failed to change directory. Check if the path is correct. Exiting."; exit 1; }
docker compose --profile study up -d || { echo "Docker Compose failed to start. Check Docker setup. Exiting."; exit 1; }
