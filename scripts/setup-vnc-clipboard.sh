#!/bin/bash
# PRIMARY <-> CLIPBOARD в X11. Запускать после x11vnc.
set -euo pipefail

export DISPLAY="${DISPLAY:-:1}"

if ! command -v autocutsel >/dev/null 2>&1; then
    exit 0
fi

pkill -u "$(id -u)" autocutsel 2>/dev/null || true
autocutsel -fork -selection CLIPBOARD
autocutsel -fork -selection PRIMARY
