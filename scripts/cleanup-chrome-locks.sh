#!/bin/bash
# Снимает зависший SingletonLock после перезапуска контейнера или падения Chrome.

set -euo pipefail

# shellcheck source=load-app-session.sh
source /usr/local/lib/cursor-desktop/load-app-session.sh

PROFILE_DIR="${HOME}/.config/google-chrome"

chrome_running() {
    pgrep -u "$(id -u)" -f "(/usr/bin/google-chrome|/opt/google/chrome)" >/dev/null 2>&1
}

remove_lock_files() {
    local base=$1
    [[ -d "${base}" ]] || return 0
    rm -f \
        "${base}/SingletonLock" \
        "${base}/SingletonSocket" \
        "${base}/SingletonCookie" \
        "${base}/lockfile" 2>/dev/null || true
    if [[ -d "${base}/Default" ]]; then
        rm -f \
            "${base}/Default/SingletonLock" \
            "${base}/Default/SingletonSocket" \
            "${base}/Default/SingletonCookie" 2>/dev/null || true
    fi
}

[[ -d "${PROFILE_DIR}" ]] || exit 0

if chrome_running; then
    exit 0
fi

remove_lock_files "${PROFILE_DIR}"
find "${PROFILE_DIR}" -maxdepth 3 \( -name SingletonLock -o -name SingletonSocket -o -name SingletonCookie \) -delete 2>/dev/null || true
