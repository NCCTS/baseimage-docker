#!/bin/bash

# source: https://gist.github.com/shime/5706655
# modified with assumption that nucrses is already installed, e.g. with apt-get

# script for installing tmux and dependencies.
# tmux will be installed in /usr/local/lib by default.

# prerequisites: - gcc
#                - wget

# define versions
tmux_version="1.9"
tmux_patch_version="a" # leave empty for stable releases

libevent_version="2.0.21"

tmux_name="tmux-$tmux_version"
tmux_relative_url="$tmux_name/$tmux_name$tmux_patch_version"
libevent_name="libevent-$libevent_version-stable"

# set the installation directory
target_dir="/usr/local"

mkdir -p /docker-build/support/build/downloads
cd /docker-build/support/build/downloads

# download source files for libevent and tmux
wget -O $libevent_name.tar.gz https://github.com/downloads/libevent/libevent/$libevent_name.tar.gz
wget -O $tmux_name.tar.gz http://sourceforge.net/projects/tmux/files/tmux/$tmux_relative_url.tar.gz/download

# libevent installation
tar xvzf $libevent_name.tar.gz
cd $libevent_name
./configure --prefix=$target_dir --disable-shared
make
make install
cd -

# tmux installation
tar xvzf ${tmux_name}*.tar.gz
cd ${tmux_name}*/

./configure CFLAGS="-I$target_dir/include -I/usr/include" \
            LDFLAGS="-L$target_dir/lib -L/usr/include -L$target_dir/include"

CPPFLAGS="-I$target_dir/include -I/usr/include" \
LDFLAGS="-static -L$target_dir/include -L/usr/include -L$target_dir/lib" \
make

cp tmux $target_dir/bin
mkdir -p /usr/local/share/man/man1
cp tmux.1 /usr/local/share/man/man1
cd -

version=`tmux -V | cut -d ' ' -f 2`
if [ -z "$version" ]; then
    echo
    echo "[error] failed to install tmux - check for errors in the above output"
    exit 1
fi
