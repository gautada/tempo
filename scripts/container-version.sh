#!/bin/sh
# ╭――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――╮
# │ VERSION - TEMPO VERSION REPORT                                       │
# ╰――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――╯
# Emits the Tempo version baked into the container. Returns "unknown" if the
# version cannot be determined.

VERSION=$(/usr/bin/tempo --version 2>/dev/null | grep -Eo '([0-9]+\.)+[0-9]+' | head -n 1)

if [ -z "$VERSION" ]; then
  printf "unknown\n"
  exit 1
fi

printf "%s\n" "$VERSION"
