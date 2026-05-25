#!/bin/bash
# Chrome в Docker: DISPLAY, HOME, D-Bus; от root → пользователь app.

set -euo pipefail

# shellcheck source=load-app-session.sh
source /usr/local/lib/cursor-desktop/load-app-session.sh
# shellcheck source=gpu-accel.sh
source /usr/local/bin/gpu-accel.sh

if [[ "$(id -u)" -eq 0 && -z "${CHROME_AS_APP:-}" ]]; then
    exec gosu app:app env CHROME_AS_APP=1 /usr/local/bin/google-chrome-stable "$@"
fi

apply_gpu_accel_env

CHROME=/usr/bin/google-chrome-stable
CHROME_ARGS=(
    --no-sandbox
    --disable-dev-shm-usage
    --no-first-run
)
while IFS= read -r flag; do
    [[ -n "${flag}" ]] && CHROME_ARGS+=("${flag}")
done < <(chrome_gpu_args)

log() {
    echo "[$(date -Iseconds)] $*" >> /tmp/chrome-open.log
}

chrome_running() {
    pgrep -u "$(id -u)" -f "(/usr/bin/google-chrome|/opt/google/chrome)" >/dev/null 2>&1
}

open_url() {
    local url=$1
    /usr/local/bin/cleanup-chrome-locks.sh

    if chrome_running; then
        log "open tab in running chrome uid=$(id -u) url=${url}"
        "${CHROME}" "${CHROME_ARGS[@]}" "${url}" >>/tmp/chrome-open.log 2>&1 &
        disown 2>/dev/null || true
        echo "Chrome (tab): ${url}"
        return 0
    fi

    log "start URL uid=$(id -u) DISPLAY=${DISPLAY} HOME=${HOME} url=${url}"
    nohup "${CHROME}" "${CHROME_ARGS[@]}" --new-window "${url}" >>/tmp/chrome-open.log 2>&1 &
    disown 2>/dev/null || true
    echo "Chrome: ${url} (DISPLAY=${DISPLAY}, log: /tmp/chrome-open.log)"
}

for arg in "$@"; do
    case "${arg}" in
        http://* | https://*)
            open_url "${arg}"
            exit 0
            ;;
    esac
done

log "start interactive uid=$(id -u) DISPLAY=${DISPLAY} argv=$*"
/usr/local/bin/cleanup-chrome-locks.sh
exec "${CHROME}" "${CHROME_ARGS[@]}" "$@"
