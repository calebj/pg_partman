## Docker Environment

If you don't have a build environment setup on your local machine, the project provides a docker container setup for your convenience. As long as Docker is installed, you can use the following commands to run tests:

```sh
# Build the image:
docker build -t partman_test_image ./docker

# Start the container. This will initialize and start Postgres, then drop to a shell.
docker run -it --name partman_test -v "$(pwd):/pg_partman" partman_test_image
```

The source code for pg_partman is mounted inside the container rather than included in the build, so any changes can be tested without rebuilding the container.

Example commands to run inside the container:

```sh
# Convenience script to build and install pg_partman, then create a database named partman_test.
# This does a fresh build+install each time, and the database is recreated if it already exists.
docker/build_for_tests.sh

# Run a specific test
pg_prove -ovf -U postgres -d partman_test test/<test_file_path>.sql

# Build, install, create DB and run all tests
docker/build_and_test.sh

# The script can run specific tests as well (relative to test/)
docker/build_and_test.sh <test_file_path>.sql
```

You can also start the container and run the tests in one command with:

```sh
# All tests
docker run --rm -it -v "$(pwd):/pg_partman" partman_test_image docker/build_and_test.sh

# Specific tests, again relative to test/
docker run --rm -it -v "$(pwd):/pg_partman" partman_test_image docker/build_and_test.sh <test_file_path>.sql
```

When finished, stop and optionally remove the container.

```sh
docker stop partman_test
docker rm partman_test
```

### Replicating the CI environment

Both the above image and the GitHub CI pipeline use the [pgxn-tools](https://github.com/pgxn/docker-pgxn-tools) image. The Dockerfile and entrypoint in this folder are meant to ease iterative development, but you can use the standalone entrypoint to run the same steps that CI does.

```sh
# Install PostgreSQL 17 and run all tests, discarding the container afterwards
docker run -it --rm -w /pg_partman --volume "$(pwd):/pg_partman" pgxn/pgxn-tools docker/pgxn_standalone_entrypoint.sh 17
```
