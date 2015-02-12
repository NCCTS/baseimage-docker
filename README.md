nccts/baseimage
===============

[![License BSD 2-Clause](https://img.shields.io/badge/license-BSD-brightgreen.svg?style=flat)](http://opensource.org/licenses/BSD-2-Clause)
[![Floobits Status](https://floobits.com/NCCTS/baseimage-docker.svg)](https://floobits.com/NCCTS/baseimage-docker/redirect)

> A Docker baseimage for convenient, composable dev and small prod environments.

* [Docker Registry](https://registry.hub.docker.com/u/nccts/baseimage/)
* [Quay.io](https://quay.io/repository/nccts/baseimage)

```shell
docker pull nccts/baseimage
# -or-
docker pull quay.io/nccts/baseimage
```

## Usage

TODO: need to check/revise semicolon usage in heredoc examples
TODO: provide examples of `docker exec` in combo w/ `/usr/local/bin/entry`

```shell
docker run -it --rm nccts/baseimage

docker run -it --rm nccts/baseimage top
docker run -it --rm nccts/baseimage 'top'
docker run -it --rm nccts/baseimage "top"

docker run -it --rm --env ENTRY_TMUX nccts/baseimage
docker run -it --rm --env ENTRY_TMUX nccts/baseimage top
docker run -it --rm --env ENTRY_TMUX \
                    --env ENTRY_SESSION=hello nccts/baseimage top

docker run -it --rm --env ENTRY_ROOT nccts/baseimage top
docker run -it --rm --env ENTRY_LOGIN=root nccts/baseimage top

docker run -it --rm --env ENTRY_TMUX nccts/baseimage \
    tmux new-window -n win0 -d top \;          \
    tmux new-window -n win1 -d top \;          \
    tmux new-window -n win2

docker run -it --rm --env ENTRY_TMUX nccts/baseimage ' \
    tmux new-window -n win0 -d "top -u root"   ; \
    tmux new-window -n win1 -d "top -u sailor" ; \
    tmux new-window -n win2'

docker run -it --rm --env ENTRY_TMUX nccts/baseimage " \
    tmux new-window -n win0 -d 'top -u root'   ; \
    tmux new-window -n win1 -d 'top -u sailor' ; \
    tmux new-window -n win2"

docker run -it --rm --env ENTRY_TMUX nccts/baseimage "$(cat << 'EOF'
    tmux new-window -n win0 -d 'top -u root'   ;
    tmux new-window -n win1 -d 'top -u sailor' ;
    tmux new-window -n win2
EOF
)"

read -r -d '' entry_cmd << 'EOF'
    tmux new-window -n win0 -d 'top -u root'   ;
    tmux new-window -n win1 -d 'top -u sailor' ;
    tmux new-window -n win2
EOF
docker run -it --rm --env ENTRY_TMUX nccts/baseimage "$entry_cmd"

read -r -d '' entry_cmd << 'EOF'
    tmux new-window -n win0 -d 'top -u root'
    tmux new-window -n win1 -d 'top -u sailor'
    tmux new-window -n win2
EOF
entry_cmd="eval $(printf "%q " "$entry_cmd")"
docker run -it --rm --env ENTRY_TMUX nccts/baseimage "$entry_cmd"

{ entry_cmd="eval $(cat)"; } << 'EOF'
    tmux new-window -n win0 -d 'top -u root'
    tmux new-window -n win1 -d 'top -u sailor'
    tmux new-window -n win2
EOF
docker run -it --rm --env ENTRY_TMUX nccts/baseimage:0.0.11 "$entry_cmd"
```

## Copyright and License

This software is Copyright &copy; 2014-2015 by the National Catholic Conference for Total Stewardship.<br>All rights reserved.

The use and distribution terms for this software are covered by the [BSD 2-Clause License](http://opensource.org/licenses/BSD-2-Clause) which can be found in the file [LICENSE](https://raw.githubusercontent.com/NCCTS/baseimage-docker/master/LICENSE) at the [root](https://github.com/NCCTS/baseimage-docker/tree/master) of this distribution. By using this software in any fashion, you are agreeing to be bound by the terms of this license. You must not remove this notice, or any other, from this software.
