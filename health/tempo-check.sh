#!/bin/sh
# ╭――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――╮
# │ TEMPO - HEALTH CHECK SCRIPT                                              │
# ╰――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――╯
# Verifies that Tempo is responding on its configured port.

PORT="${TEMPO_PORT:-3200}"
HEALTH_ENDPOINT="http://localhost:${PORT}/ready"

if ! curl -fsSL "${HEALTH_ENDPOINT}" > /dev/null 2>&1; then
    printf "Tempo is not responding on port %s\n" "${PORT}" >&2
    exit 1
fi

printf "Tempo is healthy\n"
