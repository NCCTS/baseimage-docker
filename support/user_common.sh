#!/bin/bash

rm -rf $HOME/.bash_logout

file_append () {
    echo "$1" >> "$2"
}

file_overwrite () {
    echo "$1" > "$2"
}

file_prepend () {
    local ed_cmd="1i"
    if [ ! -f "$2" ]; then
        touch "$2"
        ed_cmd="a"
    fi
    printf '%s\n' H "$ed_cmd" "$1" . w | ed -s "$2"
}

touch $HOME/.entry_env

cat "/docker-build/support/bashrc_append_$(whoami).txt" >> $HOME/.bashrc
cat /docker-build/support/bashrc_append_common.txt >> $HOME/.bashrc
cp /docker-build/support/tmux.conf $HOME/.tmux.conf
chmod 644 $HOME/.tmux.conf

git clone https://github.com/revans/bash-it.git $HOME/.bash_it
