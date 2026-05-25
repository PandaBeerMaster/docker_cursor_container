#!/bin/bash
# Синхронизация буфера обмена X11 и раскладка клавиатуры для VNC.
set -euo pipefail

export DISPLAY="${DISPLAY:-:1}"

# PRIMARY <-> CLIPBOARD — без этого копирование в приложениях часто не доходит до VNC.
if command -v autocutsel >/dev/null 2>&1; then
    pkill -u "$(id -u)" autocutsel 2>/dev/null || true
    autocutsel -fork
    autocutsel -fork -selection PRIMARY
fi

# us + ru, переключение Alt+Shift (настраивается через XKB_LAYOUT / XKB_OPTIONS).
if command -v setxkbmap >/dev/null 2>&1; then
    layout="${XKB_LAYOUT:-us,ru}"
    variant="${XKB_VARIANT:-}"
    options="${XKB_OPTIONS:-grp:alt_shift_toggle}"

    args=(-layout "${layout}")
    [[ -n "${variant}" ]] && args+=(-variant "${variant}")
    [[ -n "${options}" ]] && args+=(-option "${options}")
    setxkbmap "${args[@]}" 2>/dev/null || setxkbmap -layout us,ru -option grp:alt_shift_toggle
fi
