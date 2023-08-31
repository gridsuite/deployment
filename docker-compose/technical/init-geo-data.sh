#!/bin/bash

set -e

function send_()
{
  #curl --fail --silent --output /dev/null --header "Content-Type: application/json" --data @$1 "${@:2}"
  wget --quiet --output-document=/dev/null --header="Content-Type: application/json" --post-file="$1" "${@:2}"
}

function init_geo_data()
{
  FILE_SUBSTATIONS=/init-data/geo_data_substations.json
  FILE_LINES=/init-data/geo_data_lines.json

  ([ ! -f "$FILE_SUBSTATIONS" ] || send_ $FILE_SUBSTATIONS http://geo-data-server/v1/substations) \
  &&
  ([ ! -f "$FILE_LINES" ] || send_ $FILE_LINES http://geo-data-server/v1/lines)
}

if [ "$PROJECT_DIR_NAME" == "$PROJECT_STUDY_DIR_NAME" ] || [ "$PROJECT_DIR_NAME" == "$PROJECT_SUITE_DIR_NAME" ]
then
  until init_geo_data
  do
    echo "curl: geo-data-server is unavailable to initialize data - will retry later"
    sleep 5
  done
fi
