#!/bin/bash

function init_lines_catalog()
{
  LINES_CATALOG=/init-data/lines-catalog.json.gz
  if [ -f $LINES_CATALOG ]; then
      curl -X 'POST' -f -s -o /dev/null 'http://network-modification-server/v1/network-modifications/catalog/line_types' -F "file=@${LINES_CATALOG}"
  fi
}

until init_lines_catalog
  do
    echo "curl: network-modification-server is unavailable to initialize data - will retry later"
    sleep 5
  done
