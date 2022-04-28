#!/bin/bash

set -e

function createDatabases()
{
psql --username $POSTGRES_USER --dbname $POSTGRES_DEFAULT_DB <<-EOSQL
  create database "${DATABASE_PREFIX_NAME}ds";
  create database "${DATABASE_PREFIX_NAME}directory";
  create database "${DATABASE_PREFIX_NAME}study";
  create database "${DATABASE_PREFIX_NAME}actions";
  create database "${DATABASE_PREFIX_NAME}networkmodifications";
  create database "${DATABASE_PREFIX_NAME}merge_orchestrator";
  create database "${DATABASE_PREFIX_NAME}dynamicmappings";
  create database "${DATABASE_PREFIX_NAME}filters";
  create database "${DATABASE_PREFIX_NAME}report";
  create database "${DATABASE_PREFIX_NAME}config";
  create database "${DATABASE_PREFIX_NAME}sa";
  create database "${DATABASE_PREFIX_NAME}geo_data";
  create database "${DATABASE_PREFIX_NAME}cgmes_boundary";
  create database "${DATABASE_PREFIX_NAME}iidm";
  create database "${DATABASE_PREFIX_NAME}import_history";
  create database "${DATABASE_PREFIX_NAME}cgmes_assembling";
EOSQL
}

until pg_isready; do
  echo "psql: Postgres is unavailable to create databases - will retry later"
  sleep 2
done && createDatabases
