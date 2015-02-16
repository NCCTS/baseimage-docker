#!/bin/bash

# helper function for use in dev/prod client setting
# --------------------------------------------------
# kill_entry () {
#     local container_id=$1
#     docker exec $container_id bash -c 'kill $(cat /var/run/entry.pid)'
# }

# neet to double-check that env vars trump cmd line switches, with override by
# --unset-env, --reset-env; make sure to consider docker run and exec cases in
# various dimensions of their usage, e.g. w.r.t. command-line one-offs
# vs. Dockerfile spec of ENTRYPOINT, CMD, and so on

# need both --reset-env and --re-entry
# re_entry.sh will spec --re-entry
# the effect is to skip over the env filters and not write to .entry_env; however the usual
# source'ing of that file will apply in the sudo -i -u context; additinoal --env supplied to entry
# will be spec'd in the same way BASH_ENV is spec'd to sudo -i -u

# will need "special" flag/flag-processing to allow env vars to be passed to entry.sh / re_entry.sh
# consider:
#   eval "$([ ! ${#myarr[@]} -eq 0] && printf "%q " "${myarr[@]}") bash -c 'ls ; echo \$nibs ; echo \$jims ; ls'"
#   myarr=() ; myarr+=( nibs=123 ) ; myarr+=( jims='456 789' )
# could loop over --env pairs supplied to entry.sh with help of getopt,getopts
# the goal here is to allow docker exec to be supplied with vars which will get poperly passed
# on to the string-command/heredoc-command, since sudo will strip them out if set in the string/heredoc
# the thing to remember is that we don't want those to be (or to need to be) proc'd with ENV_ENTRY_WHITE
# etc. since we don't want to mess w/ .entry_env in an docker exec context; they should just be
# shunted in along with ENTRY_BASH_ENV and BASH_ENV; in the docker run case, since the Dockerfile
# entrypoint wouldn't use the --env flag, there simply won't be any

# write out an "expectations" markdown file which can serve as a set of tests
#   to be performed to see that entry.sh and all dotfiles, etc. are in place as
#   expected

# non-interactive default command would be to sleep indefinitely
#   but don't use infinity because that works out to ~24 days; instead sleep for 86400 in a loop

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

# the following are helpful refs but not reliable in the context of entry itself
# ------------------------------------------------------------------------------
# entry_interactive=
# [[ $- == *i* ]] \
#     && entry_interactive=true \
#         || entry_interactive=false

# entry_login_shell=
# shopt -q login_shell \
#     && entry_login_shell=true \
#         || entry_login_shell=false

# consider moving the array below (but seralized as string) into Dockerfile
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
    ENTRY_RE_ENTRY%
    r
    ENTRY_RESET_ENV+
    E:
    ENTRY_ROOT%
    R
    ENTRY_SESSION:
    s:
    ENTRY_TMUX%
    t
    ENTRY_UNSET_ENV+
    U:
    ENTRY_USERS+
    u:
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

# This text can and should be dynamically generated; needs option descriptions as well
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
  -r, --re-entry (=false)
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
    [ "$1" = "--" ] && break
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

# for pair in "${ENTRY_ENV[@]}"; do
#     v="$(echo "$pair" | grep -o ^.\*= | sed 's/=$//')"
#     v_test=$(eval "if [ \"\${$v+set}\" = set ]; then echo true; fi")
#     if [ "$v_test" != true ]; then
#         eval "$(printf "%q " "$pair")"
#     fi
# done
# unset pair

# ^ same as above but sets/overwrites whether or not the var is already set
for pair in "${ENTRY_ENV[@]}"; do
done
unset pair

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
            eval "$v=\"\$opt_$v\""
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

            eval "declare -a $v=(\${$v[@]})"

entry_white=false
entry_black=false
if [ "${ENTRY_ENV_FILTER_WHITE+set}" = set ]; then
    entry_white=true
    declare -a entry_white_norm=($(echo "${ENTRY_ENV_FILTER_WHITE[@]}" | \
                                          sed 's/^ *//' | \
                                          sed 's/ *$//' | \
                                          sed 's/ \+/ /g'))
fi
if [ "${ENTRY_ENV_FILTER_BLACK+set}" = set ]; then
    entry_black=true
    declare -a entry_black_norm=($(echo "${ENTRY_ENV_FILTER_BLACK[@]}" | \
                                          sed 's/^ *//' | \
                                          sed 's/ *$//' | \
                                          sed 's/ \+/ /g'))
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






# !!!
# debug w/ printenv before moving on
# !!!





echo
echo "-----------------------"
echo EARLY DEV EXIT '$? = 123'
echo "-----------------------"
echo







entry_env_home=$(eval echo ~$ENTRY_LOGIN)
if [ "$ENTRY_LOGIN" = "root" ]; then
    ENTRY_ROOT=true
fi

entry_filter_temp=
entry_filter_final=
if [[ "$entry_white" = true || "$entry_black" = true ]]; then
    if [[ "$entry_white" = true && "$entry_black" = true ]]; then
        if [ "$ENTRY_ENV_FILTER_FIRST" = "white" ]; then
            if [ "${entry_white_norm[@]}" = "$ENTRY_ENV_FILTER_ALL" ]; then
                entry_filter_temp=$(cat /etc/container_environment.sh)
            else
                entry_filter_temp=$(sed '/export '"$(echo $entry_white_norm | sed 's/ /\\|export /g')"'/!d' \
                                        < /etc/container_environment.sh)
            fi
            if [ "${entry_black_norm[@]}" != "$ENTRY_ENV_FILTER_ALL" ]; then
                entry_filter_final="$(echo "$entry_filter_temp" | \
                    sed '/export '"$(echo $entry_black_norm | sed 's/ /\\|export /g')"'/d')"
                # if it was "$ENTRY_ENV_FILTER_ALL" then don't write to .entry_env
            fi
        else
            if [ "${entry_black_norm[@]}" != "$ENTRY_ENV_FILTER_ALL" ]; then
                entry_filter_temp=$(sed '/export '"$(echo $entry_black_norm | sed 's/ /\\|export /g')"'/d' \
                                        < /etc/container_environment.sh)
                # if it was "$ENTRY_ENV_FILTER_ALL" then entry_filter_temp remains empty
            fi
            if [ "${entry_white_norm[@]}" != "$ENTRY_ENV_FILTER_ALL" ]; then
                entry_filter_final="$(echo "$entry_filter_temp" | \
                    sed '/export '"$(echo $entry_white_norm | sed 's/ /\\|export /g')"'/!d')"
            else
                entry_filter_final="$entry_filter_temp"
            fi
        fi
    else
        if [ "$entry_white" = true ]; then
            if [ "$entry_white_norm" = "$ENTRY_ENV_FILTER_ALL" ]; then
                entry_filter_final="$(cat /etc/container_environment.sh)"
            else
                entry_filter_final="$(sed '/export '"$(echo $entry_white_norm | sed 's/ /\\|export /g')"'/!d' \
                    < /etc/container_environment.sh)"
            fi
        fi
        if [ "$entry_black" = true ]; then
            if [ "$entry_black_norm" != "$ENTRY_ENV_FILTER_ALL" ]; then
                entry_filter_final="$(sed '/export '"$(echo $entry_black_norm | sed 's/ /\\|export /g')"'/d' \
                    < /etc/container_environment.sh)"
                # if it was "$ENTRY_ENV_FILTER_ALL" then don't write to .entry_env
            fi
        fi
    fi
fi

if [ "${entry_filter_final:+set}" = set ]; then
    for u in "${entry_users[@]}"; do
        h=$(eval echo "~$u")
        echo "$entry_filter_final" > $h/.entry_env
    done
    unset u h
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
