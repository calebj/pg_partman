#!/usr/bin/env bash
set -e

pg_createcluster 17 test --start -p 5432 --pgoption max_locks_per_transaction=128 -- -A trust

exec $@
