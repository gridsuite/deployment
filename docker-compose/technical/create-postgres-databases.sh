#!/bin/bash

set -e

function createDatabases()
{
psql --username postgres --dbname postgres <<-EOSQL
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
EOSQL
}

until pg_isready; do
  echo "psql: Postgres is unavailable to create databases - will retry later"
  sleep 2
done && createDatabases