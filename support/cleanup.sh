#!/bin/bash

apt-get -y remove --auto-remove \
        autoconf \
        automake \
        dpkg-dev \
        g++ \
        gcc \
        libc6-dev \
        libncurses5-dev \
        libpcre3-dev \
        liblzma-dev \
        make \
        pkg-config \
        software-properties-common \
        zlib1g-dev
apt-get -y autoclean
apt-get -y clean
apt-get -y autoremove
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
