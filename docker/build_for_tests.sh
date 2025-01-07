#!/usr/bin/env bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cd "$SCRIPT_DIR/.."

make && make install

psql -U postgres -c "DROP DATABASE IF EXISTS partman_test"
psql -U postgres -c "CREATE DATABASE partman_test"
psql -U postgres -d partman_test -c "CREATE EXTENSION pgtap"
psql -U postgres -d partman_test -c "CREATE SCHEMA partman"
psql -U postgres -d partman_test -c "CREATE EXTENSION pg_partman SCHEMA partman"
