#!/bin/bash

set -e

function curl_()
{
  curl -f -s -o /dev/null -H "Content-Type: multipart/form-data" "$@"
}

function init_merging_data()
{
  FILE_TSOS=/init-data/tsos.json
  FILE_BUSINESS_PROCESSES=/init-data/business_processes.json

  ([ ! -f "$FILE_TSOS" ] || curl_ -F "file=@$FILE_TSOS;type=application/json" http://cgmes-boundary-server/v1/tsos) \
  &&
  ([ ! -f "$FILE_BUSINESS_PROCESSES" ] || curl_ -F "file=@$FILE_BUSINESS_PROCESSES;type=application/json" http://cgmes-boundary-server/v1/business-processes)
}

if [ "$PROJECT_DIR_NAME" == "$PROJECT_MERGING_DIR_NAME" ] || [ "$PROJECT_DIR_NAME" == "$PROJECT_SUITE_DIR_NAME" ]
then
  until init_merging_data
  do
    echo "curl: cgmes-boundary-server is unavailable to initialize data - will retry later"
    sleep 5
  done
fi
