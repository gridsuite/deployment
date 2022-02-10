#!/bin/bash

set -e

psql -v ON_ERROR_STOP=1 --username postgres --dbname postgres <<-EOSQL
  create database ds;
  create database directory;
  create database study;
  create database actions;
  create database networkmodifications;
  create database merge_orchestrator;
  create database dynamicmappings;
  create database filters;
  create database report;
  create database config;
EOSQL
