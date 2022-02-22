#!/bin/bash

set -e

echo "PROJECT_DIR_NAME=$PROJECT_DIR_NAME"

/init-geo-data.sh &
/init-merging-data.sh &

exec docker-entrypoint.sh "$@"
