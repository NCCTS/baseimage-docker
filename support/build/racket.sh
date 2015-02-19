#!/bin/bash

mkdir -p /docker-build/support/build/downloads
cd /docker-build/support/build/downloads

wget http://mirror.racket-lang.org/installers/6.1.1/racket-minimal-6.1.1-x86_64-linux-ubuntu-precise.sh
chmod +x ./racket-minimal-6.1.1-x86_64-linux-ubuntu-precise.sh
./racket-minimal-6.1.1-x86_64-linux-ubuntu-precise.sh --unix-style --dest /usr/local --create-dir
