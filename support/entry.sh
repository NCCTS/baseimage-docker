#!/bin/bash

sess_name="$1"
shift
if [ "${SESS:+set}" = set ]; then
    sess_name="$SESS"
fi

tmux_ctx=false
if [ "${TMUX_INIT+set}" = set ]; then
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

filter_order_first="white"
if [ ! "${ENV_BLACK_THEN_WHITE+set}" = set ]; then
    filter_order_first="black"
fi
if [ ! "${ENV_WHITE_THEN_BLACK+set}" = set ]; then
    filter_order_first="white"
fi
white_list=false
black_list=false
if [[ $root_ctx = true && ! "${ENV_WHITE:+set}" = set ]]; then
    ENV_WHITE='*ALL*'
fi
if [ "${ENV_WHITE:+set}" = set ]; then
    white_list=true
    ENV_WHITE=$(echo $ENV_WHITE | sed 's/^ *//' | sed 's/ *$//' | sed 's/ \+/ /g')
fi
if [ "${ENV_BLACK:+set}" = set ]; then
    black_list=true
    ENV_BLACK=$(echo $ENV_BLACK | sed 's/^ *//' | sed 's/ *$//' | sed 's/ \+/ /g')
fi

filter_temp=""
entry_env_home=$(eval echo ~$login_ctx)
if [[ $white_list = true || $black_list = true ]]; then
    if [[ $white_list = true && $black_list = true ]]; then
        if [ $filter_order_first="white" ]; then
            if [ "$ENV_WHITE" = '*ALL*' ]; then
                filter_temp=$(cat /etc/container_environment.sh)
            else
                filter_temp=$(sed '/export '"$(echo $ENV_WHITE | sed 's/ /\\|export /g')"'/!d' \
                                  < /etc/container_environment.sh)
            fi
            if [ "$ENV_BLACK" != '*ALL*' ]; then
                echo "$filter_temp" | \
                    sed '/export '"$(echo $ENV_BLACK | sed 's/ /\\|export /g')"'/d' \
                        > $entry_env_home/.entry_env
                # if it was '*ALL*' then don't write to .entry_env
            fi
        else
            if [ "$ENV_BLACK" != '*ALL*' ]; then
                filter_temp=$(sed '/export '"$(echo $ENV_BLACK | sed 's/ /\\|export /g')"'/d' \
                                  < /etc/container_environment.sh)
                # if it was '*ALL*' then filter_temp remains the empty string
            fi
            if [ "$ENV_WHITE" != '*ALL*' ]; then
                echo "$filter_temp" | \
                    sed '/export '"$(echo $ENV_WHITE | sed 's/ /\\|export /g')"'/!d' \
                        > $entry_env_home/.entry_env
            else
                echo "$filter_temp" > $entry_env_home/.entry_env
            fi
        fi
    else
        if [ $white_list = true ]; then
            if [ "$ENV_WHITE" = '*ALL*' ]; then
                cat /etc/container_environment.sh > $entry_env_home/.entry_env
            else
                sed '/export '"$(echo $ENV_WHITE | sed 's/ /\\|export /g')"'/!d' \
                    < /etc/container_environment.sh \
                    > $entry_env_home/.entry_env
            fi
        fi
        if [ $black_list = true ]; then
            if [ "$ENV_BLACK" != '*ALL*' ]; then
                sed '/export '"$(echo $ENV_BLACK | sed 's/ /\\|export /g')"'/d' \
                    < /etc/container_environment.sh \
                    > $entry_env_home/.entry_env
                # if it was '*ALL*' then don't write to .entry_env
            fi
        fi
    fi
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
