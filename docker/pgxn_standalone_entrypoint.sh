#!/usr/bin/env bash
set -e

if [ ! -n $1 ] ; then
    echo "Usage: $0 <PG_VERSION> [test_to_run.sql ...]" >&2
    exit 1
elif ! [[ $1 =~ ^[0-9]+$ ]]; then
    echo "PG_VERSION must be a positive integer." >&2
    exit 1
else
    PG_VERSION=$1
    shift
fi

CREATE_OPTIONS="--pgoption max_locks_per_transaction=128" pg-start $PG_VERSION postgresql-$PG_VERSION-pgtap

exec /pg_partman/docker/build_and_test.sh $@
