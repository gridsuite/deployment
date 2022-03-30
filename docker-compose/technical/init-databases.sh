#!/bin/bash

set -e

/create-postgres-databases.sh &

/init-geo-data.sh &
/init-merging-data.sh &

exec docker-entrypoint.sh "$@"
