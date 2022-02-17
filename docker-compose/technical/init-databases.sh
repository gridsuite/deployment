#!/bin/bash

set -e

echo "PROJECT_DIR_NAME=$PROJECT_DIR_NAME"

if [ "$PROJECT_DIR_NAME" == "study" ] || [ "$PROJECT_DIR_NAME" == "suite" ]
then
  until curl -s http://geo-data-server/v1/substations; do
    echo "curl: geo-data-server is unavailable to initialize data - will retry later"
    sleep 5
  done \
  && curl -H 'Content-Type: application/json' -d@geo_data_substations.json 'http://geo-data-server/v1/substations' \
  && curl -H 'Content-Type: application/json' -d@geo_data_lines.json 'http://geo-data-server/v1/lines' \
  &
fi

exec docker-entrypoint.sh "$@"
