# if not running interactively, don't do anything
case $- in
    *i*) ;;
    *) return;;
esac

# don't check mail
unset MAILCHECK

# don't put duplicate lines or lines starting with space in the history.
# see bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# if set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# load Bash It
export BASH_IT=$HOME/.bash_it
export BASH_IT_THEME="zork"
. $BASH_IT/bash_it.sh

# alias definitions
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

export EDITOR="emacs -Q"
export GIT_EDITOR="emacs -Q"

if [ -f ~/.bash_env ]; then
    . ~/.bash_env
fi

if [[ "${ENTRY_BASH_ENV+set}" = set && "${BASH_ENV+set}" = set ]]; then
    unset ENTRY_BASH_ENV
    unset BASH_ENV
    if [ -f ~/.entry_env ]; then
        . ~/.entry_env
    fi
fi