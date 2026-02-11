#!/bin/bash

function curl_()
{
  curl -f -s -o /dev/null -H "Content-Type: application/json" "$@"
}

function init_geo_data()
{
  FILE_SUBSTATIONS=/init-data/geo_data_substations.json
  FILE_LINES=/init-data/geo_data_lines.json

  ([ ! -f "$FILE_SUBSTATIONS" ] || curl_ -d@$FILE_SUBSTATIONS http://172.17.0.1:8087/v1/substations) \
  &&
  ([ ! -f "$FILE_LINES" ] || curl_ -d@$FILE_LINES http://172.17.0.1:8087/v1/lines)
}

until init_geo_data
  do
    echo "curl: geo-data-server is unavailable to initialize data - will retry later"
    sleep 5
  done
