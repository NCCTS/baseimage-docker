#!/bin/bash

mkdir -p /docker-build/support/Downloads
cd /docker-build/support/Downloads
git clone https://github.com/facebook/watchman.git
cd /docker-build/support/Downloads/watchman
git checkout v3.0.0
./autogen.sh
./configure
make
make install
