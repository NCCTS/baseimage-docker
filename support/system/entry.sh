#!/bin/bash

# for reference
# -------------
# shopt -q login_shell && echo login-shell || echo not-login-shell
# [[ $- == *i* ]] && echo interactive || echo not-interactive
# `getopt --test; echo $?`
#    "4" - no bug
#    "0" - bug
# see: http://j.mp/1DrioUl (stackoverflow.com)
# see also: http://journal.missiondata.com/post/63404248482/long-arguments-and-getops

# helper function for use in dev/prod client setting
# --------------------------------------------------
# kill_entry () {
#     local container_id=$1
#     docker exec $container_id bash -c 'kill $(cat /var/run/entry.pid)'
# }

# need a --no-forward (-N) flag which has 3 possible values: interactive, not-interactive, always
# get dirs under /etc/service and match names against "-forwarder$"; for all matches, issue cmd:
#   sv stop /etc/service/...-forwarder

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
    echo "$entry_pid" > /var/run/entry.pid
fi

entry_vars=(
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
entry_vars_only=()
for (( i=0; i<${#entry_vars[@]} ; i+=2 )) ; do
    v=${entry_vars[i]}
    entry_vars_only+=($v)
done
unset i v

# types: array (+), scalar (:), marker-true (%), marker-false (@)
entry_vars_types=()
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
        echo $v
        echo "unknown ENTRY_ var type"
        exit 1
    fi
    entry_vars_types+=($t)
done
unset v t

entry_vars_plain=()
for v in "${entry_vars_only[@]}"; do
    entry_vars_plain+=($(echo $v | sed 's/\+$//' | \
                                sed 's/:$//'     | \
                                sed 's/%$//'     | \
                                sed 's/@$//'))
done
unset v

entry_vars_def=()
for v in "${entry_vars_plain[@]}"; do
    entry_vars_def+=($v"_DEFAULT")
done
unset v

long_options=()
for (( i=0; i<${#entry_vars[@]} ; i+=2 )) ; do
    lo=${entry_vars[i]}
    long_options+=($(echo $lo | sed 's/\+$/:/' | \
                            sed 's/%$//'       | \
                            sed 's/@$//'       | \
                            sed 's/^ENTRY_//'  | \
                            sed 's/_/-/g'      | \
                            tr '[:upper:]' '[:lower:]'))
done
unset i lo
long_options_plain=($(echo "${long_options[@]}" | sed 's/://g'))

short_options=()
for (( i=1; i<${#entry_vars[@]} ; i+=2 )) ; do
    so=${entry_vars[i]}
    short_options+=($so)
done
unset i so
short_options_plain=($(echo "${short_options[@]}" | sed 's/://g'))

# This text can and should be dynamically generated; needs option descriptions as well
read -r -d '' usage_text_short << EOF

Options:

  -e, --env=[]
  -a, --env-filter-all=$ENTRY_ENV_ALL_DEFAULT
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

read -r -d '' usage_text << EOF

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

  --env FOO=bar --env BAZ=quux

Interpretation of options described below, \`val\` indicates default setting:

  -s{hort}, --long=val      =>  arg required (val is scalar)
  -s, --long=[]|[val ...]   =>  arg required (val is array member)
  -s, --long (=val)         =>  no arg (val is boolean, signifies missing opt)

$usage_text_short

EOF

usage_short () {
    echo
    echo "Use --help option for more information"
    echo
    echo "$usage_text_short"
    exit 0
}

usage () {
    echo
    echo "$usage_text"
    exit 0
}

[ $# -eq 0 ] && usage_short
gop=$(getopt -n$0 \
             -u \
             -a \
             --longoptions \
             "$(echo ${long_options[@]} | sed 's/ \+/,/g')" \
             "$(echo ${short_options[@]} | sed 's/ \+//g')" \
             "$@")

if [ $? != 0 ]; then
    usage_short
fi

eval set -- "$gop"
unset gop

search_long () {
    local i=0
    local str
    for str in "${long_options_plain[@]}"; do
        if [ "--$str" = "$1" ]; then
            echo "$i"
            return
        else
            ((i++))
        fi
    done
    echo "-1"
}

search_short () {
    local i=0
    local str
    for str in "${short_options_plain[@]}"; do
        if [ "-$str" = "$1" ]; then
            echo "$i"
            return
        else
            ((i++))
        fi
    done
    echo "-1"
}

while [ $# -gt 0 ]; do
    [ $1 = "--" ] && break
    i=$(search_long $1)
    if [ "$i" = "-1" ]; then
        i=$(search_short $1)
    fi
    if [ "$i" = "-1" ]; then
        echo "unknown entry option"
        exit 1
    fi
    t=${entry_vars_types[i]}
    v=${entry_vars_plain[i]}
    opt_v="opt_"$v
    case "$t" in
        array)
            eval "$opt_v+=($2)"
            shift
            ;;
        scalar)
            eval "$opt_v=$2"
            shift
            ;;
        marker-true)
            eval "$opt_v=true"
            ;;
        marker-false)
            eval "$opt_v=false"
            ;;
    esac
    shift
done
unset i t v opt_v

[ "$opt_ENTRY_HELP" = true ] && usage

if [ "$opt_ENTRY_KILL" = true ]; then
    if [ -e /var/run/entry.pid ]; then
        kill $(cat /var/run/entry.pid)
        exit $?
    else
        echo "--kill option requires the existence of /var/run/entry.pid"
        exit 1
    fi
fi

# ----------------------------

echo
echo "-----------------------"
echo EARLY DEV EXIT '$? = 123'
echo "-----------------------"
echo

exit 123

# ----------------------------

# 0. set ENTRY_ env vars which correspond to the --unset-env, --reset-env, --env,
#    i.e. the options themselves, not their values
# 1. unset env vars per ENTRY_UNSET_ENV
# 2. set env vars per ENTRY_RESET_ENV to their _DEFAULT values, but only if the var **is** already set
# 3. set env vars per ENTRY_ENV, but only if the var is *not* already set; do not account for ENTRY_
#    var types (can revisit this decision later)
# 4. set ENTRY_ env vars per other entry --options, but only if the env var is *not* already set
#    and opt_ENTRY_ env var **is** set; make sure to account for type
# 5. set ENTRY_ env vars which are not otherwise set, using the _DEFAULT values; make sure to
#    account for type
# 6. handle special cases, e.g. flipping ENTRY_ROOT if ENTRY_LOGIN is "root"

## DONT USE LCASE APPROACH BELOW, use the ENTRY_ env vars, which per the steps above should be properly set

for (( i=0; i<${#entry_vars_only[@]} ; i+=1 )) ; do
    v=${entry_vars_only[i]}
    v_def=$v"_DEFAULT"
    v_def_test=$(eval "if [ \"\${$v_def+set}\" = set ]; then echo true; fi")
    if [ "$v_def_test" = true ]; then
        v_lcase=$(echo $v | tr '[:upper:]' '[:lower:]')
        t=${entry_vars_types[i]}
        if [ "$t" = "array" ]; then
            eval "$v_lcase=(\$$v_def)"
        elif [ "$t" = "scalar" ]; then
            eval "$v_lcase=\$$v_def"
        elif [[ "$t" = "marker-true" || "$t" = "marker-false" ]]; then
            eval v_def_actual=\$$v_def
            if [ "$v_def_actual" = true ]; then
                eval "$v_lcase=true"
            elif [ "$v_def_actual" = false ]; then
                eval "$v_lcase=false"
            else
                echo "ENTRY_ var marker types must be \"true\" or \"false\""
                exit 1
            fi
        else
            echo "unknown ENTRY_ var type"
            exit 1
        fi
    fi
done
unset i v v_def v_def_test v_lcase t


# !!!
# debug w/ printenv before moving on
# !!!

# need to think about how --env,--unset-env,--reset-env and --re-entry (or the lack of it)
# affect how ~/.entry_env is processed and how env vars are passed through sudo


entry_login_shell=
shopt -q login_shell \
    && entry_login_shell=true \
        || entry_login_shell=false

entry_interactive=
[[ $- == *i* ]] \
    && entry_interactive=true \
        || entry_interactive=false

entry_tty=true
if [ "$(tty 2>&1)" = "not a tty" ]; then
    entry_tty=false
fi

entry_tmux=false
if [ "${ENTRY_TMUX+set}" = set ]; then
    entry_tmux=true
fi
if [[ $entry_tmux = true && $entry_tty = false ]]; then
    echo "cannot start tmux without a tty:" '$(tty 2>&1) =' $(tty 2>&1) 1>&2
    exit 1
fi

entry_users=(${ENTRY_USERS_DEFAULT// / })
if [ "${ENTRY_USERS:+set}" = set ]; then
    entry_users=(${ENTRY_USERS// / })
fi

entry_session="$ENTRY_SESSION_DEFAULT"
if [ "${ENTRY_SESSION:+set}" = set ]; then
    entry_session="$ENTRY_SESSION"
fi
# while getopts "s:" flag; do
#     case "$flag" in
#         s) entry_session=$OPTARG;;
#     esac
# done
# shift $((OPTIND-1))
entry_session_flag="-s $entry_session"
entry_cmd=$*

entry_login="$ENTRY_LOGIN_DEFAULT"
if [ "${ENTRY_LOGIN:+set}" = set ]; then
    entry_login="$ENTRY_LOGIN"
fi

entry_root=false
if [ "$entry_login" = "root" ]; then
    entry_root=true
fi
if [ "${ENTRY_ROOT+set}" = set ]; then
    entry_login="root"
    entry_root=true
fi

entry_env_home=$(eval echo ~$entry_login)

entry_filter_first="$ENTRY_FILTER_FIRST_DEFAULT"
if [ "${ENTRY_FILTER_FIRST:+set}" = set ]; then
    if [[ "$ENTRY_FILTER_FIRST" = "black" || "$ENTRY_FILTER_FIRST" = "white" ]]; then
        entry_filter_first="$ENTRY_FILTER_FIRST"
    fi
fi

entry_env_all="$ENTRY_ENV_ALL_DEFAULT"
if [ "${ENTRY_ENV_ALL:+set}" = set ]; then
    entry_env_all="$ENTRY_ENV_ALL"
fi

white_list=false
black_list=false
if [[ $entry_root = true && ! "${ENTRY_ENV_WHITE:+set}" = set ]]; then
    ENTRY_ENV_WHITE="$entry_env_all"
fi
if [ "${ENTRY_ENV_WHITE:+set}" = set ]; then
    white_list=true
    ENTRY_ENV_WHITE=$(echo $ENTRY_ENV_WHITE | sed 's/^ *//' | sed 's/ *$//' | sed 's/ \+/ /g')
fi
if [ "${ENTRY_ENV_BLACK:+set}" = set ]; then
    black_list=true
    ENTRY_ENV_BLACK=$(echo $ENTRY_ENV_BLACK | sed 's/^ *//' | sed 's/ *$//' | sed 's/ \+/ /g')
fi

filter_temp=
filter_final=
if [[ $white_list = true || $black_list = true ]]; then
    if [[ $white_list = true && $black_list = true ]]; then
        if [ "$entry_filter_first" = "white" ]; then
            if [ "$ENTRY_ENV_WHITE" = "$entry_env_all" ]; then
                filter_temp=$(cat /etc/container_environment.sh)
            else
                filter_temp=$(sed '/export '"$(echo $ENTRY_ENV_WHITE | sed 's/ /\\|export /g')"'/!d' \
                                  < /etc/container_environment.sh)
            fi
            if [ "$ENTRY_ENV_BLACK" != "$entry_env_all" ]; then
                filter_final="$(echo "$filter_temp" | \
                    sed '/export '"$(echo $ENTRY_ENV_BLACK | sed 's/ /\\|export /g')"'/d')"
                # if it was "$entry_env_all" then don't write to .entry_env
            fi
        else
            if [ "$ENTRY_ENV_BLACK" != "$entry_env_all" ]; then
                filter_temp=$(sed '/export '"$(echo $ENTRY_ENV_BLACK | sed 's/ /\\|export /g')"'/d' \
                                  < /etc/container_environment.sh)
                # if it was "$entry_env_all" then filter_temp remains empty
            fi
            if [ "$ENTRY_ENV_WHITE" != "$entry_env_all" ]; then
                filter_final="$(echo "$filter_temp" | \
                    sed '/export '"$(echo $ENTRY_ENV_WHITE | sed 's/ /\\|export /g')"'/!d')"
            else
                filter_final="$filter_temp"
            fi
        fi
    else
        if [ $white_list = true ]; then
            if [ "$ENTRY_ENV_WHITE" = "$entry_env_all" ]; then
                filter_final="$(cat /etc/container_environment.sh)"
            else
                filter_final="$(sed '/export '"$(echo $ENTRY_ENV_WHITE | sed 's/ /\\|export /g')"'/!d' \
                    < /etc/container_environment.sh)"
            fi
        fi
        if [ $black_list = true ]; then
            if [ "$ENTRY_ENV_BLACK" != "$entry_env_all" ]; then
                filter_final="$(sed '/export '"$(echo $ENTRY_ENV_BLACK | sed 's/ /\\|export /g')"'/d' \
                    < /etc/container_environment.sh)"
                # if it was "$entry_env_all" then don't write to .entry_env
            fi
        fi
    fi
    if [ "${filter_final:+set}" = set ]; then
        for u in "${entry_users[@]}"; do
            h=$(eval echo "~$u")
            echo "$filter_final" > $h/.entry_env
        done
    fi
fi

if [ $entry_tmux = true ]; then
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
