#!/bin/bash

mkdir -p /docker-build/support/build/downloads/parallel
cd /docker-build/support/build/downloads/parallel

wget -O - pi.dk/3 | bash
echo will cite | parallel --bibtex
