#!/bin/bash
# Раскладка X11: русская ЙЦУКЕН (winkeys) + US, переключение Alt+Shift.
set -euo pipefail

export DISPLAY="${DISPLAY:-:1}"

model="${XKB_MODEL:-pc105}"
layout="${XKB_LAYOUT:-ru,us}"
variant="${XKB_VARIANT:-,winkeys}"
options="${XKB_OPTIONS:-grp:alt_shift_toggle,grp_led:scroll}"

export XKB_DEFAULT_MODEL="${model}"
export XKB_DEFAULT_LAYOUT="${layout}"
export XKB_DEFAULT_VARIANT="${variant}"
export XKB_DEFAULT_OPTIONS="${options}"

if ! command -v setxkbmap >/dev/null 2>&1; then
    exit 0
fi

args=(-model "${model}" -layout "${layout}")
[[ -n "${variant}" ]] && args+=(-variant "${variant}")
[[ -n "${options}" ]] && args+=(-option "${options}")

if ! setxkbmap "${args[@]}"; then
    setxkbmap -model pc105 -layout ru,us -variant ,winkeys \
        -option grp:alt_shift_toggle,grp_led:scroll
fi
