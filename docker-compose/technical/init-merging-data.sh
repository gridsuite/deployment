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
  FILE_BOUNDARIES_TP=/init-data/20200202T0000Z__ENTSOE_TPBD_001.xml
  FILE_BOUNDARIES_EQ=/init-data/20200202T0000Z__ENTSOE_EQBD_001.xml

  ([ ! -f "$FILE_TSOS" ] || curl_ -F "file=@$FILE_TSOS;type=application/json" http://cgmes-boundary-server/v1/tsos) \
  &&
  ([ ! -f "$FILE_BUSINESS_PROCESSES" ] || curl_ -F "file=@$FILE_BUSINESS_PROCESSES;type=application/json" http://cgmes-boundary-server/v1/business-processes) \
  &&
  ([ ! -f "$FILE_BOUNDARIES_TP" ] || curl_ -F "file=@$FILE_BOUNDARIES_TP;type=application/json" http://cgmes-boundary-server/v1/boundaries) \
  &&
  ([ ! -f "$FILE_BOUNDARIES_EQ" ] || curl_ -F "file=@$FILE_BOUNDARIES_EQ;type=application/json" http://cgmes-boundary-server/v1/boundaries)
}

if [ "$PROJECT_DIR_NAME" == "$PROJECT_MERGING_DIR_NAME" ] || [ "$PROJECT_DIR_NAME" == "$PROJECT_SUITE_DIR_NAME" ]
then
  until init_merging_data
  do
    echo "curl: cgmes-boundary-server is unavailable to initialize data - will retry later"
    sleep 5
  done
fi
