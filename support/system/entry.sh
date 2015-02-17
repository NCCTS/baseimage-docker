#!/bin/bash

# helper function for use in dev/prod client setting
# --------------------------------------------------
# kill_entry () {
#     local container_id=$1
#     docker exec $container_id bash -c 'kill $(cat /var/run/entry.pid)'
# }

# the following are helpful references
# ------------------------------------
# entry_interactive=
# [[ $- == *i* ]] \
#     && entry_interactive=true \
#         || entry_interactive=false

# entry_login_shell=
# shopt -q login_shell \
#     && entry_login_shell=true \
#         || entry_login_shell=false

# consider moving entry_vars array (but seralized as a string) into Dockerfile

# think about --append-env to complement --unset-env and --reset-env; could be
# helpful for ENTRY_ env vars and those set w/ --env

# write out an "expectations" markdown file which can serve as a set of tests to
# be performed to see that entry.sh and all dotfiles, etc. are in place as
# expected... better yet, learn to use tcl expect framework to write tests
# for `docker run` and `docker exec`

entry_pid=$$
entry_ppid=$(ps -p ${pid:-$$} -o ppid= | awk '{ print $1 }')
if [ "$entry_ppid" = "1" ]; then
    echo $entry_pid > /var/run/entry.pid
fi

entry_tty=true
if [ "$(tty 2>&1)" = "not a tty" ]; then
    entry_tty=false
fi

# assume the session is interactive if there's a tty
entry_interactive=
if [ "$entry_tty" = true ]; then
    entry_interactive=true
else
    entry_interactive=false
fi

# types: array (+), scalar (:), marker-true (%), marker-false (@)
declare -a entry_vars=(
    ENTRY_ENV+
    e:
    ENTRY_ENV_FILTER_ALL:
    a:
    ENTRY_ENV_FILTER_BLACK+
    b:
    ENTRY_ENV_FILTER_FIRST:
    f:
    ENTRY_ENV_FILTER_NONE:
    n:
    ENTRY_ENV_FILTER_WHITE+
    w:
    ENTRY_HELP%
    h
    ENTRY_KILL%
    k
    ENTRY_LOGIN:
    l:
    ENTRY_NO_FORWARD:
    F:
    ENTRY_RESET_ENV+
    r:
    ENTRY_ROOT%
    R
    ENTRY_SESSION:
    s:
    ENTRY_TMUX%
    t
    ENTRY_UNSET_ENV+
    u:
    ENTRY_USERS+
    U:
)
declare -a entry_vars_only=()
for (( i=0; i<${#entry_vars[@]} ; i+=2 )) ; do
    v=${entry_vars[i]}
    entry_vars_only+=($v)
done
unset i v

declare -a entry_vars_plain=()
for v in "${entry_vars_only[@]}"; do
    entry_vars_plain+=($(echo $v | \
                                sed 's/\+$//' | \
                                sed 's/:$//'  | \
                                sed 's/%$//'  | \
                                sed 's/@$//'))
done
unset v

declare -a entry_vars_types=()
for v in "${entry_vars_only[@]}"; do
    if [[ "$v" =~ \+$ ]]; then
        t="array"
    elif [[ "$v" =~ :$ ]]; then
        t="scalar"
    elif [[ "$v" =~ %$ ]]; then
        t="marker-true"
    elif [[ "$v" =~ @$ ]]; then
        t="marker-false"
    else
        echo "unknown ENTRY_ var type"
        exit 1
    fi
    entry_vars_types+=($t)
done
unset v t

declare -a entry_long_options=()
for (( i=0; i<${#entry_vars[@]} ; i+=2 )) ; do
    lo=${entry_vars[i]}
    entry_long_options+=($(echo $lo | \
                                  sed 's/\+$/:/'    | \
                                  sed 's/%$//'      | \
                                  sed 's/@$//'      | \
                                  sed 's/^ENTRY_//' | \
                                  sed 's/_/-/g'     | \
                                  tr '[:upper:]' '[:lower:]'))
done
unset i lo
declare -a entry_long_options_plain=($(echo ${entry_long_options[@]} | \
                                              sed 's/://g'))

declare -a entry_short_options=()
for (( i=1; i<${#entry_vars[@]} ; i+=2 )) ; do
    so=${entry_vars[i]}
    entry_short_options+=($so)
done
unset i so
declare -a entry_short_options_plain=($(echo ${entry_short_options[@]} | \
                                               sed 's/://g'))

# This text can/should be dynamically generated; needs opt-descriptions as well
read -r -d '' entry_usage_text_short << EOF

Options:

  -e, --env=[]
  -a, --env-filter-all=$ENTRY_ENV_FILTER_ALL_DEFAULT
  -b, --env-filter-black=[]
  -f, --env-filter-first=white
  -n, --env-filter-none=:NONE:
  -w, --env-filter-white=[]
  -h, --help (=false)
  -l, --login=sailor
  -E, --reset-env=[]
  -R, --root (=false)
  -s, --session=base
  -t, --tmux (=false)
  -U, --unset-env=[]
  -u, --users=[root captain sailor]

EOF

read -r -d '' entry_usage_text << EOF

Usage: entry [OPTIONS] [COMMAND]

Run one or more commands upon entering a configurable environment. Use with
\`docker run\` and \`docker exec\` for containers derived from nccts/baseimage.

It is reommended to avoid using spaces to separate options from their arguments:

  --option argument

Prefer this form instead:

  --option=argument

Specify array members with multiple \`opt=val\` pairs for the same option:

  --option=one --option=two

A special case is the --env option:

  --env=FOO=bar --env=BAZ=quux

For readability's sake prefer:

  --env FOO=bar --env BAZ=quux

Interpretation of options described below, \`val\` indicates default setting:

  -s{hort}, --long=val      =>  arg required (val is scalar)
  -s, --long=[]|[val ...]   =>  arg required (val is array member)
  -s, --long (=val)         =>  no arg (val is boolean, signifies missing opt)

$entry_usage_text_short

EOF

entry_usage_short () {
    echo
    echo "Use --help option for more information"
    echo
    echo "$entry_usage_text_short"
    exit 0
}

entry_usage () {
    echo
    echo "$entry_usage_text"
    exit 0
}

[ $# -eq 0 ] && entry_usage_short
gop="$(getopt -n$0 \
             -a \
             --longoptions \
             "$(echo ${entry_long_options[@]} | sed 's/ \+/,/g')" \
             "$(echo ${entry_short_options[@]} | sed 's/ \+//g')" \
             "$@")"

if [ $? != 0 ]; then
    entry_usage_short
fi

eval set -- "$gop"
unset gop

entry_search_long () {
    local i=0
    local str
    for str in "${entry_long_options_plain[@]}"; do
        if [ "--$str" = "$1" ]; then
            echo "$i"
            return
        else
            ((i++))
        fi
    done
    unset str
    echo "-1"
}

entry_search_short () {
    local i=0
    local str
    for str in "${entry_short_options_plain[@]}"; do
        if [ "-$str" = "$1" ]; then
            echo "$i"
            return
        else
            ((i++))
        fi
    done
    unset str
    echo "-1"
}

while [ $# -gt 0 ]; do
    [ "$1" = "--" ] && shift && break
    i=$(entry_search_long "$1")
    if [ "$i" = "-1" ]; then
        i=$(entry_search_short "$1")
    fi
    if [ "$i" = "-1" ]; then
        case "$t" in
            array)
                eval "opt_v_len=\${#opt_$v[@]}"
                (( --opt_v_len ))
                eval "opt_$v[$opt_v_len]+=\" \$1\""
                shift
                ;;
            scalar)
                eval "opt_$v+=\" \$1\""
                shift
                ;;
        esac
    else
        t=${entry_vars_types[i]}
        v=${entry_vars_plain[i]}
        opt_v_test=$(eval "if [ \"\${opt_$v+set}\" = set ]; then echo true; fi")
        if [ "$opt_v_test" != true ]; then
            eval "declare -a opt_$v=()"
        fi
        case "$t" in
            array)
                eval "opt_$v+=(\"\$2\")"
                shift
                ;;
            scalar)
                eval "opt_$v=\"\$2\""
                shift
                ;;
            marker-true)
                eval "opt_$v=true"
                ;;
            marker-false)
                eval "opt_$v=false"
                ;;
        esac
        shift
    fi
done
unset i opt_v_len t v opt_v_test
entry_cmd="$*"

[ "$opt_ENTRY_HELP" = true ] && entry_usage

if [ "$opt_ENTRY_KILL" = true ]; then
    if [ -e /var/run/entry.pid ]; then
        kill $(cat /var/run/entry.pid)
        exit $?
    else
        echo "--kill option requires the existence of /var/run/entry.pid"
        exit 1
    fi
fi

entry_start=(ENTRY_ENV ENTRY_RESET_ENV ENTRY_UNSET_ENV)
for v in "${entry_start[@]}"; do
    opt_v_test=$(eval "if [ \"\${opt_$v+set}\" = set ]; then echo true; fi")
    if [ "$opt_v_test" = true ]; then
        eval "declare -a $v=()"
        eval "for vv in \${!opt_$v[@]}; do $v[\$vv]=\"\${opt_$v[\$vv]}\"; done"
    else
        v_def=$v"_DEFAULT"
        eval "declare -a $v=(\$$v_def)"
    fi
done
unset entry_start v opt_v_test v_def

for v in "${ENTRY_UNSET_ENV[@]}"; do
    eval "unset $v"
done
unset v

for v in "${ENTRY_RESET_ENV[@]}"; do
    v_def=$v"_DEFAULT"
    eval "export $v=\"\$$v_def\""
done
unset v v_def

for pair in "${ENTRY_ENV[@]}"; do
    v="$(echo "$pair" | grep -o ^.\*= | sed 's/=$//')"
    v_test=$(eval "if [ \"\${$v+set}\" = set ]; then echo true; fi")
    if [ "$v_test" != true ]; then
        eval "$(printf "%q " "$pair")"
    fi
done
unset pair v v_test
# ^ same as above but sets/overwrites whether or not the var is already set
# for pair in "${ENTRY_ENV[@]}"; do
#     eval "export $(printf "%q " "$pair")"
# done
# unset pair

entry_search_start () {
    local i=0
    local str
    for str in "${entry_start[@]}"; do
        if [ "-$str" = "$1" ]; then
            echo "$i"
            return
        else
            ((i++))
        fi
    done
    unset str
    echo "-1"
}

for v in "${entry_vars_plain[@]}"; do
    i=$(entry_search_start $v)
    if [ "$i" = "-1" ]; then
        opt_v_test=$(eval "if [ \"\${opt_$v+set}\" = set ]; then echo true; fi")
        if [ "$opt_v_test" = true ]; then
            eval "$v=\"\${opt_$v[@]}\""
        fi
    fi
done
unset v i opt_v_test

for i in "${!entry_vars_plain[@]}"; do
    v=${entry_vars_plain[$i]}
    v_test=$(eval "if [ \"\${$v+set}\" = set ]; then echo true; fi")
    if [ "$v_test" != true ]; then
        v_def=$v"_DEFAULT"
        t=${entry_vars_types[$i]}
        case "$t" in
            array)
                eval "declare -a $v=(\$$v_def)"
                ;;
            scalar)
                eval "$v=\"\$$v_def\""
                ;;
            marker-true)
                eval "$v=\$$v_def"
                ;;
            marker-false)
                eval "$v=\$$v_def"
                ;;
        esac
    fi
done
unset i v v_test v_def t

# final pass to make sure arrays are arrays, etc.
for i in "${!entry_vars_plain[@]}"; do
    v=${entry_vars_plain[$i]}
    t=${entry_vars_types[$i]}
    case "$t" in
        array)
            eval "declare -a $v=(\${$v[@]})"
            ;;
        scalar)
            eval "$v=\"\$$v\""
            ;;
        marker-true)
            eval "$v=\$$v"
            ;;
        marker-false)
            eval "$v=\$$v"
            ;;
    esac
done
unset i v t

entry_white=false
entry_black=false
if [ "${ENTRY_ENV_FILTER_WHITE+set}" = set ]; then
    entry_white=true
    # declare -a entry_white_norm=($(echo "${ENTRY_ENV_FILTER_WHITE[@]}" | \
    #                                       sed 's/^ *//' | \
    #                                       sed 's/ *$//' | \
    #                                       sed 's/ \+/ /g'))
    declare -a entry_white_norm=(${ENTRY_ENV_FILTER_WHITE[@]})
fi
if [ "${ENTRY_ENV_FILTER_BLACK+set}" = set ]; then
    entry_black=true
    # declare -a entry_black_norm=($(echo "${ENTRY_ENV_FILTER_BLACK[@]}" | \
    #                                       sed 's/^ *//' | \
    #                                       sed 's/ *$//' | \
    #                                       sed 's/ \+/ /g'))
    declare -a entry_black_norm=(${ENTRY_ENV_FILTER_BLACK[@]})
fi

# serialiaze arrays, export ENTRY_ vars
for i in "${!entry_vars_plain[@]}"; do
    v=${entry_vars_plain[$i]}
    t=${entry_vars_types[$i]}
    case "$t" in
        array)
            eval "v_copy=\"\${$v[@]}\""
            eval "unset $v"
            if [ "$v_copy" != "" ]; then
                eval "export $v=\"\$v_copy\""
            else
                eval "export $v="
            fi
            ;;
        scalar)
            eval "export $v=\"\$$v\""
            ;;
        marker-true)
            eval "export $v=\$$v"
            ;;
        marker-false)
            eval "export $v=\$$v"
            ;;
    esac
done
unset i v t v_copy

if [[ "$ENTRY_TMUX" = true && "$entry_tty" = false ]]; then
    echo "cannot start tmux without a tty:" '$(tty 2>&1) =' $(tty 2>&1) 1>&2
    exit 1
fi
entry_session_flag="-s $ENTRY_SESSION"

entry_stop_forward () {
    local svc=$(echo /etc/service/* | tr ' ' '\n')
    declare -a svc_fwd=($(echo "$svc" | sed '/-forwarder$/!d'))
    for s in "${svc_fwd[@]}"; do
        sv stop $s
    done
    unset s
}

if [ "$entry_ppid" = "1" ]; then
    if [ "$ENTRY_NO_FORWARD" != "never" ]; then
        if [ "$ENTRY_NO_FORWARD" = "always" ]; then
            entry_stop_forward
        else
            if [[ "$ENTRY_NO_FORWARD" = "interactive" \
                        &&  "$entry_interactive" = true \
                            || \
                            "$ENTRY_NO_FORWARD" = "not-interactive" \
                                &&  "$entry_interactive" = false ]]; then
                entry_stop_forward
            fi
        fi
    fi
fi

if [ "$ENTRY_LOGIN" = "root" ]; then
    ENTRY_ROOT=true
fi
if [ "$ENTRY_ROOT" = "true" ]; then
    ENTRY_LOGIN="root"
fi
entry_env_home=$(eval echo ~$ENTRY_LOGIN)

entry_filter_temp=
entry_filter_final=
if [[ "$entry_white" = true || "$entry_black" = true ]]; then
    envvars_temp_file="$(envvars)"
    envvars_txt="$(cat "$envvars_temp_file")"
    if [[ "$entry_white" = true && "$entry_black" = true ]]; then
        if [ "$ENTRY_ENV_FILTER_FIRST" = "white" ]; then
            if [ "$entry_white_norm" != "$ENTRY_ENV_FILTER_NONE" ]; then
                if [ "$entry_white_norm" = "$ENTRY_ENV_FILTER_ALL" ]; then
                    entry_filter_temp="$envvars_txt"
                else
                    entry_filter_temp="$(echo "$envvars_txt" | \
                                           sed -z "$(echo ${entry_white_norm[@]} | \
                                                     sed 's/ /\\| /g')"'/!d')"
                fi
            fi
            if [ "$entry_black_norm" != "$ENTRY_ENV_FILTER_ALL" ]; then
                if [ "$entry_black_norm" = "$ENTRY_ENV_FILTER_NONE" ]; then
                    entry_filter_final="$entry_filter_temp"
                else
                    entry_filter_final="$(echo "$entry_filter_temp" | \
                                           sed -z "$(echo ${entry_black_norm[@]} | \
                                                     sed 's/ /\\| /g')"'/d')"
                fi
            fi
        else
            if [ "$entry_black_norm" != "$ENTRY_ENV_FILTER_ALL" ]; then
                if [ "$entry_black_norm" = "$ENTRY_ENV_FILTER_NONE" ]; then
                    entry_filter_temp="$envvars_txt"
                else
                    entry_filter_temp="$(echo "$envvars_txt" | \
                                           sed -z "$(echo ${entry_black_norm[@]} | \
                                                     sed 's/ /\\| /g')"'/d')"
                fi
            fi
            if [ "$entry_white_norm" != "$ENTRY_ENV_FILTER_NONE" ]; then
                if [ "$entry_white_norm" = "$ENTRY_ENV_FILTER_ALL" ]; then
                    entry_filter_final="$entry_filter_temp"
                else
                    entry_filter_final="$(echo "$entry_filter_temp" | \
                                           sed -z "$(echo ${entry_white_norm[@]} | \
                                                            sed 's/ /\\| /g')"'/!d')"
                fi
            fi
        fi
    else
        if [ "$entry_white" = true ]; then
            if [ "$entry_white_norm" != "$ENTRY_ENV_FILTER_NONE" ]; then
                if [ "$entry_white_norm" = "$ENTRY_ENV_FILTER_ALL" ]; then
                    entry_filter_final="$envvars_txt"
                else
                    entry_filter_final="$(echo "$envvars_txt" | \
                                           sed -z "$(echo ${entry_white_norm[@]} | \
                                                     sed 's/ /\\| /g')"'/!d')"
                fi
            fi
        fi
        if [ "$entry_black" = true ]; then
            if [ "$entry_black_norm" != "$ENTRY_ENV_FILTER_ALL" ]; then
                if [ "$entry_black_norm" = "$ENTRY_ENV_FILTER_NONE" ]; then
                    entry_filter_final="$envvars_txt"
                else
                    entry_filter_final="$(echo "$envvars_txt" | \
                                                 sed -z "$(echo ${entry_black_norm[@]} | \
                                                     sed 's/ /\\| /g')"'/d')"
                fi
            fi
        fi
    fi
    entry_filter_final="$(echo "$entry_filter_final" | tr '\000' ' ')"
fi
rm "$envvars_temp_file"
unset entry_filter_temp envvars_temp_file envvars_txt

entry_bash_env_preserve=
if [ "${BASH_ENV:+set}" = set ]; then
    entry_bash_env_preserve="ENTRY_BASH_ENV_PRESERVE=$BASH_ENV"
fi
unset entry_filter_temp entry_filter_final

if [ "$entry_tmux" = true ]; then
    if [ -n "$entry_cmd" ]; then
        tmux_cmd=(tmux new-session -A $entry_session_flag "$entry_cmd")
        sudo_cmd=(sudo -i -u \
                       $entry_login \
                       "ENTRY_BASH_ENV=" \
                       "BASH_ENV=$entry_env_home/.bash_env_wrap" \
                       bash -c \
                       "$(printf "%q " "${tmux_cmd[@]}")")
        eval "$(printf "%q " "${sudo_cmd[@]}")"
    else
        sudo -i -u \
             $entry_login \
             "ENTRY_BASH_ENV=" \
             "BASH_ENV=$entry_env_home/.bash_env_wrap" \
             tmux new-session -A $entry_session_flag
    fi
else
    if [ -n "$entry_cmd" ]; then
        sudo_cmd=(sudo -i -u \
                       $entry_login \
                       "ENTRY_BASH_ENV=" \
                       "BASH_ENV=$entry_env_home/.bash_env_wrap" \
                       bash -c \
                       "$entry_cmd")
        eval "$(printf "%q " "${sudo_cmd[@]}")"
    else
        sudo -i -u \
             $entry_login \
             "ENTRY_BASH_ENV=" \
             "BASH_ENV=$entry_env_home/.bash_env_wrap" \
             bash -l
    fi
fi
