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
        g++ \
        gcc \
        git-core \
        libc6-dev \
        libncurses5-dev \
        libpcre3-dev \
        liblzma-dev \
        make \
        man-db \
        pkg-config \
        software-properties-common \
        wget \
        zlib1g-dev

cp /docker-build/support/system/entry.sh /usr/local/bin/entry
chmod 744 /usr/local/bin/entry

cp /docker-build/support/system/re_entry.sh /usr/local/bin/re_entry
chmod 744 /usr/local/bin/re_entry
ln -s /usr/local/bin/re_entry /usr/local/bin/re-entry
ln -s /usr/local/bin/re_entry /usr/local/bin/reentry