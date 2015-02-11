#!/bin/bash

mkdir -p /docker-build/support/build/downloads
cd /docker-build/support/build/downloads

git clone -b v3.0.0 --depth 1 https://github.com/facebook/watchman.git
cd watchman

./autogen.sh
./configure
make
make install
