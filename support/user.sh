#!/bin/bash

echo -e '%sudo\tALL=NOPASSWD: ALL' >> /etc/sudoers

# unprivileged user 'sailor'
adduser --disabled-password --gecos "" sailor
# sudo user 'captain'
adduser --disabled-password --gecos "" captain
usermod -a -G sudo captain

entry_users=(${ENTRY_USERS_DEFAULT// / })
for u in "${entry_users[@]}"; do
    v=("common" "$u")
    h=$(eval echo "~$u")
    for w in "${v[@]}"; do
        user_script="/docker-build/support/user/user_$w.sh"
        if [ -f "$user_script" ]; then
            sudo -i -u "$u" bash -c "BASH_ENV=$h/.bash_env $user_script"
        fi
    done
done
