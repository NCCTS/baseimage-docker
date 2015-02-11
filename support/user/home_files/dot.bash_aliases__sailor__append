
# Safety catch, i.e. when attached with `docker exec`
read -r -d '' exit_heredoc <<'EOF'
WARNING !!! WATCH OUT !!! VORSICHT !!!
     Do you really want to exit?
            `command exit`
WARNING !!! WATCH OUT !!! VORSICHT !!!
EOF

alias exit='echo ; echo -e "$exit_heredoc" ; echo'
