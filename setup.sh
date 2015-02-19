#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# packages,system config
/docker-build/support/config.sh

# build,install from sources
/docker-build/support/build.sh

# user config
/docker-build/support/user.sh

# cleanup
/docker-build/support/cleanup.sh
