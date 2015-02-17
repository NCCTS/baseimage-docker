# Docker version 1.5.0, build a8a31ef
FROM phusion/baseimage:0.9.16

# nccts/baseimage
# version: 0.0.11
MAINTAINER "Michael Bradley" <michael.bradley@nccts.org>
# Ave, maris stella, Dei mater alma, atque semper virgo, felix cœli porta.

# build timestamp
ENV REFRESHED_AT [2015-01-30 Sun 23:37]

# set ENTRY env var defaults
ENV ENTRY_ENV_DEFAULT= \
    ENTRY_ENV_FILTER_ALL_DEFAULT=:ALL: \
    ENTRY_ENV_FILTER_BLACK_DEFAULT= \
    ENTRY_ENV_FILTER_FIRST_DEFAULT=white \
    ENTRY_ENV_FILTER_NONE_DEFAULT=:NONE: \
    ENTRY_ENV_FILTER_WHITE_DEFAULT="HOSTNAME PATH" \
    ENTRY_HELP_DEFAULT=false \
    ENTRY_KILL_DEFAULT=false \
    ENTRY_LOGIN_DEFAULT=sailor \
    ENTRY_NO_FORWARD_DEFAULT=interactive \
    ENTRY_RESET_ENV_DEFAULT= \
    ENTRY_ROOT_DEFAULT=false \
    ENTRY_SESSION_DEFAULT=base \
    ENTRY_TMUX_DEFAULT=false \
    ENTRY_UNSET_ENV_DEFAULT= \
    ENTRY_USERS_DEFAULT="root captain sailor"

# completely disable sshd service
RUN rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh

# add supporting files for the build
ADD . /docker-build

# run main setup script, cleanup supporting files
RUN chmod -R 777 /docker-build
RUN /docker-build/setup.sh && rm -rf /docker-build

# use phusion/baseimage's init system as the entrypoint:
# 'entry' starts shell (or tmux) as the 'sailor' user by default
# (tmux: with a session named 'base')
ENTRYPOINT ["/sbin/my_init", "--", "/usr/local/bin/entry", "--"]
CMD [""]

# see the README for example usage
