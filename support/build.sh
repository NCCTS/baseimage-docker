#!/bin/bash

build_scripts=( /docker-build/support/build/*.sh )
readarray -t sorted < <(for s in "${build_scripts[@]}"; do echo "$s"; done | sort)

for script in "${sorted[@]}"; do
    "$script"
done
