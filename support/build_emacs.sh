#!/bin/bash

mkdir -p /docker-build/support/Downloads
cd /docker-build/support/Downloads
wget ftp://ftp.gnu.org/gnu/emacs/emacs-24.4.tar.xz
tar xf emacs-24.4.tar.xz
cd emacs-24.4
./configure
make
make install
