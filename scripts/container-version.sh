#!/bin/sh
# ╭――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――╮
# │ VERSION - TEMPO VERSION REPORT                                          │
# ╰――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――╯
# This script returns the Tempo version packaged in the container.

VERSION=$(/usr/bin/tempo --version | awk '{print $3}' | tr -d '[:space:]')

if [ -z "$VERSION" ]; then
    printf "unknown\n"
    exit 1
fi

printf "%s\n" "$VERSION"
