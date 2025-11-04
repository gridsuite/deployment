#!/bin/bash

set -e

/create-postgres-databases.sh &
/init-geo-data.sh &
/init-lines-catalog.sh &

exec docker-entrypoint.sh "$@"
