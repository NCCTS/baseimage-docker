#!/bin/bash

locale-gen --purge en_US.UTF-8
cat /docker-build/support/system/default_locale > /etc/default/locale

apt-get update
apt-get -y upgrade
apt-get -y install \
        autoconf \
        automake \
        bash-completion \
        curl \
        dpkg-dev \
        ed \
        expect \
        g++ \
        gcc \
        git-core \
        htop \
        iftop \
        libc6-dev \
        libncurses5-dev \
        libpcre3-dev \
        liblzma-dev \
        make \
        man-db \
        pkg-config \
        rlwrap \
        software-properties-common \
        tcl \
        wget \
        zlib1g-dev

cp /docker-build/support/system/entry.sh /usr/local/bin/entry
chmod 744 /usr/local/bin/entry

cp /docker-build/support/system/envvars.py /usr/local/bin/envvars
chmod 755 /usr/local/bin/envvars
