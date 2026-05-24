#!/bin/bash
# Подключить окружение графической сессии (Xvfb + D-Bus).

if [[ -f /tmp/app-session.env ]]; then
    set -a
    # shellcheck source=/dev/null
    source /tmp/app-session.env
    set +a
fi

export DISPLAY="${DISPLAY:-:1}"
export HOME="${HOME:-/home/app}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/runtime-app}"
mkdir -p "${XDG_RUNTIME_DIR}" 2>/dev/null || true
