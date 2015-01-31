export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8

# set TERM
export TERM=xterm-256color
[ -n "$TMUX" ] && export TERM=screen-256color

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    case ":$PATH:" in
        *":$HOME/bin:"*) :;; # already there
        *) export PATH="$HOME/bin:$PATH";;
    esac
fi

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

export -f file_append
export -f file_overwrite
export -f file_prepend
