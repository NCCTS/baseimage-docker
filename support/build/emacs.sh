#!/bin/bash

mkdir -p /docker-build/support/build/downloads
cd /docker-build/support/build/downloads

wget ftp://ftp.gnu.org/gnu/emacs/emacs-24.4.tar.xz
tar xf emacs-24.4.tar.xz

cd emacs-24.4
./configure
make
make install
