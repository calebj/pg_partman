#!/usr/bin/env bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cd "$SCRIPT_DIR/.."

docker/build_for_tests.sh

cd test

pg_prove --dbname partman_test --username postgres --ext .sql --comments --verbose --failures ${@:-.}
