#!/bin/bash

set -e

function send_()
{
  curl --fail --silent --output /dev/null --header "Content-Type: multipart/form-data" --form "file=@$1;type=application/json" "$2"
  #Wget does not currently support multipart/form-data for transmitting POST data; only application/x-www-form-urlencoded.
  #wget --quiet --output-document=/dev/null --header="Content-Type: multipart/form-data" --post-file=$1 $2
}

function init_merging_data()
{
  FILE_TSOS=/init-data/tsos.json
  FILE_BUSINESS_PROCESSES=/init-data/business_processes.json

  ([ ! -f "$FILE_TSOS" ] || send_ $FILE_TSOS http://cgmes-boundary-server/v1/tsos) \
  &&
  ([ ! -f "$FILE_BUSINESS_PROCESSES" ] || send_ $FILE_BUSINESS_PROCESSES http://cgmes-boundary-server/v1/business-processes)
}

if [ "$PROJECT_DIR_NAME" == "$PROJECT_MERGING_DIR_NAME" ] || [ "$PROJECT_DIR_NAME" == "$PROJECT_SUITE_DIR_NAME" ]
then
  until init_merging_data
  do
    echo "curl: cgmes-boundary-server is unavailable to initialize data - will retry later"
    sleep 5
  done
fi
