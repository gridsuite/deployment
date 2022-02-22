#!/bin/bash

set -e

cat > create_keyspaces.cql <<EOF
CREATE KEYSPACE IF NOT EXISTS iidm WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };
CREATE KEYSPACE IF NOT EXISTS geo_data WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1};
CREATE KEYSPACE IF NOT EXISTS cgmes_boundary WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };
CREATE KEYSPACE IF NOT EXISTS cgmes_assembling WITH REPLICATION = {'class' : 'SimpleStrategy', 'replication_factor' : 1 };
CREATE KEYSPACE IF NOT EXISTS import_history WITH REPLICATION = {'class' : 'SimpleStrategy', 'replication_factor' : 1 };
EOF

echo "USE iidm;" > init_keyspaces.cql
curl https://raw.githubusercontent.com/powsybl/powsybl-network-store/main/network-store-server/src/main/resources/iidm.cql >> init_keyspaces.cql
echo "USE geo_data;" >> init_keyspaces.cql
curl https://raw.githubusercontent.com/powsybl/powsybl-geo-data/main/geo-data-server/src/main/resources/geo_data.cql >> init_keyspaces.cql
echo "USE cgmes_boundary;" >> init_keyspaces.cql
curl https://raw.githubusercontent.com/gridsuite/cgmes-boundary-server/main/src/main/resources/cgmes_boundary.cql  >> init_keyspaces.cql
echo "USE cgmes_assembling;" >> init_keyspaces.cql
curl https://raw.githubusercontent.com/gridsuite/cgmes-assembling-job/main/src/main/resources/cgmes_assembling.cql >> init_keyspaces.cql
echo "USE import_history;" >> init_keyspaces.cql
curl https://raw.githubusercontent.com/gridsuite/case-import-job/main/src/main/resources/import_history.cql >> init_keyspaces.cql

until cqlsh -f /create_keyspaces.cql; do
  echo "cqlsh: Cassandra is unavailable to initialize keyspaces - will retry later"
  sleep 2
done && cqlsh -f /init_keyspaces.cql &

exec /docker-entrypoint.sh "$@"