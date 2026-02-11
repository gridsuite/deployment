#!/bin/bash

set -e

function curl_()
{
  curl -f -s -o /dev/null -H "Content-Type: application/json" "$@"
}

function init_geo_data()
{
  FILE_SUBSTATIONS=/init-data/geo_data_substations.json
  FILE_LINES=/init-data/geo_data_lines.json

  ([ ! -f "$FILE_SUBSTATIONS" ] || curl_ -d@$FILE_SUBSTATIONS http://geo-data-server/v1/substations) \
  &&
  ([ ! -f "$FILE_LINES" ] || curl_ -d@$FILE_LINES http://geo-data-server/v1/lines)
}

SHOULD_INIT_GEO_DATA="${SHOULD_INIT_GEO_DATA:-false}"

if [ "$SHOULD_INIT_GEO_DATA" = "true" ]; then
  until init_geo_data
    do
      echo "curl: geo-data-server is unavailable to initialize data - will retry later"
      sleep 5
    done
fi
