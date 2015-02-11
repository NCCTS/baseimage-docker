#!/bin/bash

mkdir -p /docker-build/support/build/downloads
cd /docker-build/support/build/downloads

git clone -b 0.29.1 --depth 1 https://github.com/ggreer/the_silver_searcher.git
cd the_silver_searcher

./build.sh
make install
