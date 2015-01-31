# Docker version 1.4.1, build 5bc2ff8
FROM phusion/baseimage:0.9.16

# nccts/baseimage
# Version: 0.0.11
MAINTAINER "Michael Bradley" <michael.bradley@nccts.org>
# Ave, maris stella, Dei mater alma, atque semper virgo, felix cœli porta.

# Cache buster
ENV REFRESHED_AT [2015-01-22 Thu 21:54]

# Set environment variables
ENV HOME /root

# Completely disable sshd
RUN rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh

# Add supporting files for the build
ADD . /docker-build

# Run main setup script, cleanup supporting files
RUN chmod -R 777 /docker-build
RUN /docker-build/setup.sh && rm -rf /docker-build

ENV ENTRY_SESS_DEFAULT base

# Use phusion/baseimage's init system as the entrypoint:
# 'entry' starts shell (or tmux) as the 'sailor' user by default
# (tmux: with a session named 'base')
ENTRYPOINT ["/sbin/my_init", "--", "/usr/local/bin/entry", "--"]
CMD [""]

# example usage
# --------------------------------------------------
# docker run -it --rm nccts/baseimage
# docker run -it --rm nccts/baseimage top
# docker run -it --rm nccts/baseimage 'top'
# docker run -it --rm nccts/baseimage "top"

# docker run -it --rm --env TMUX_INIT nccts/baseimage
# docker run -it --rm --env TMUX_INIT nccts/baseimage top
# docker run -it --rm --env TMUX_INIT --env SESS=hello nccts/baseimage top

# docker run -it --rm --env ROOT nccts/baseimage top
# docker run -it --rm --env LOGIN=root nccts/baseimage top

# docker run -it --rm --env TMUX_INIT nccts/baseimage \
#     tmux new-window -n win0 -d top \;          \
#     tmux new-window -n win1 -d top \;          \
#     tmux new-window -n win2

# docker run -it --rm --env TMUX_INIT nccts/baseimage ' \
#     tmux new-window -n win0 -d "top -u root"   ; \
#     tmux new-window -n win1 -d "top -u sailor" ; \
#     tmux new-window -n win2'

# docker run -it --rm --env TMUX_INIT nccts/baseimage " \
#     tmux new-window -n win0 -d 'top -u root'   ; \
#     tmux new-window -n win1 -d 'top -u sailor' ; \
#     tmux new-window -n win2"
