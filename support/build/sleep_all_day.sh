#!/bin/bash

cd /docker-build/support/build/sleep_all_day

gcc -o sleep_all_day sleep_all_day.c
cp sleep_all_day /usr/local/bin/sleep_all_day
chmod 755 /usr/local/bin/sleep_all_day
