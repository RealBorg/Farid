#!/bin/sh
dbicdump \
    -o dump_directory=./lib \
    -o generate_pod=0 \
    -o naming=preserve \
    Farid::Schema \
    dbi:Pg:dbname=ninkilim
