#!/bin/bash

sess_name="$1"
shift
if [ "${SESS:+set}" = set ]; then
    sess_name="$SESS"
fi

tmux_ctx=false
if [ "${TMUX+set}" = set ]; then
    tmux_ctx=true
fi

login_ctx="sailor"
if [ "${LOGIN:+set}" = set ]; then
    login_ctx="$LOGIN"
fi

root_ctx=false
if [ "$login_ctx" = "root" ]; then
    root_ctx=true
fi
if [ "${ROOT+set}" = set ]; then
    login_ctx="root"
    root_ctx=true
fi

if [ $tmux_ctx = true ]; then
    if [ -n "$*" ]; then
        tmux_cmd=(exec tmux new-session -s "$sess_name" "$*")
        sudo_cmd=(sudo -i -u "$login_ctx" -- exec bash -i -c "$(printf "%q " "${tmux_cmd[@]}")")
        eval "exec $(printf "%q " "${sudo_cmd[@]}")"
    else
        exec sudo -i -u $login_ctx -- exec bash -i -c "exec tmux new-session -s $sess_name"
    fi
else
    if [ -n "$*" ]; then
        sudo_cmd=(sudo -i -u "$login_ctx" -- exec bash -i -c "$*")
        eval "exec $(printf "%q " "${sudo_cmd[@]}")"
    else
        exec sudo -i -u $login_ctx
    fi
fi
