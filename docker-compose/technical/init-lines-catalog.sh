#!/bin/bash

set -e

function init_lines_catalog()
{
  CATALOG_EXAMPLE=/init-data/lines-catalog.json
  if [ -f $CATALOG_EXAMPLE ]; then
      curl -X 'POST' -f -s -o /dev/null 'http://network-modification-server/v1/network-modifications/catalog/line_types'  -H "Content-Type: application/json" -H 'accept: application/json' --data @${CATALOG_EXAMPLE}
  fi
}

if [ "$PROJECT_DIR_NAME" == "$PROJECT_STUDY_DIR_NAME" ] || [ "$PROJECT_DIR_NAME" == "$PROJECT_SUITE_DIR_NAME" ]
then
  until init_lines_catalog
  do
    echo "curl: network-modification-server is unavailable to initialize data - will retry later"
    sleep 5
  done
fi