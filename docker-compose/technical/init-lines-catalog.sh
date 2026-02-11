#!/bin/bash

set -e

function init_lines_catalog()
{
  LINES_CATALOG=/init-data/lines-catalog.json.gz
  if [ -f $LINES_CATALOG ]; then
      curl -X 'POST' --noproxy '*' -f -s -o /dev/null 'http://network-modification-server/v1/network-modifications/catalog/line_types' -F "file=@${LINES_CATALOG}"
  fi
}

SHOULD_INIT_LINES_CATALOG="${SHOULD_INIT_LINES_CATALOG:-false}"

if [ "$SHOULD_INIT_LINES_CATALOG" = "true" ]
then
  until init_lines_catalog
  do
    echo "curl: network-modification-server is unavailable to initialize data - will retry later"
    sleep 5
  done
fi
