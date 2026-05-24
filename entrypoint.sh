#!/bin/bash
# Запуск Xvfb, Openbox и x11vnc (порт 9999, без пароля).
# При старте от root — выравнивает права на $HOME и переключается на пользователя app.

set -euo pipefail

export DISPLAY="${DISPLAY:-:1}"
export HOME="${HOME:-/home/app}"
VNC_PORT="${VNC_PORT:-9999}"
VNC_WIDTH="${VNC_WIDTH:-1920}"
VNC_HEIGHT="${VNC_HEIGHT:-1080}"
VNC_DEPTH="${VNC_DEPTH:-24}"

# Опционально: VNC_RESOLUTION=2560x1440 (перекрывает VNC_WIDTH/VNC_HEIGHT)
if [[ -n "${VNC_RESOLUTION:-}" ]]; then
    if [[ "${VNC_RESOLUTION}" =~ ^([0-9]+)x([0-9]+)$ ]]; then
        VNC_WIDTH="${BASH_REMATCH[1]}"
        VNC_HEIGHT="${BASH_REMATCH[2]}"
    else
        echo "entrypoint: VNC_RESOLUTION must be WIDTHxHEIGHT (e.g. 1920x1080), got: ${VNC_RESOLUTION}" >&2
        exit 1
    fi
fi

for v in VNC_WIDTH VNC_HEIGHT VNC_DEPTH; do
    if [[ ! "${!v}" =~ ^[0-9]+$ ]]; then
        echo "entrypoint: ${v} must be a positive integer, got: ${!v}" >&2
        exit 1
    fi
done

VNC_SCREEN="${VNC_WIDTH}x${VNC_HEIGHT}x${VNC_DEPTH}"

ensure_profile_dirs() {
    mkdir -p \
        "${HOME}/.config/Cursor" \
        "${HOME}/.cursor" \
        "${HOME}/.config/google-chrome" \
        "${HOME}/.config/openbox"
}

start_as_app() {
    ensure_profile_dirs

    rm -f /tmp/.X"${DISPLAY#:}"-lock 2>/dev/null || true
    rm -f "/tmp/.X11-unix/X${DISPLAY#:}" 2>/dev/null || true

    Xvfb "${DISPLAY}" -screen 0 "${VNC_SCREEN}" -ac +extension GLX +render -noreset &
    XVFB_PID=$!

    sleep 1

    if command -v dbus-launch >/dev/null 2>&1; then
        eval "$(dbus-launch --sh-syntax)" || true
        export DBUS_SESSION_BUS_ADDRESS
    fi

    /usr/local/bin/save-app-session.sh

    # Зависший Chrome после перезапуска контейнера (SingletonLock / pid 60)
    pkill -u "$(id -u)" -f "(/usr/bin/google-chrome|/opt/google/chrome)" 2>/dev/null || true
    sleep 0.5
    /usr/local/bin/cleanup-chrome-locks.sh

    /usr/local/bin/setup-default-browser.sh

    export BROWSER=/usr/local/bin/open-external-url
    export CHROME_EXECUTABLE=/usr/local/bin/google-chrome-stable

    openbox &
    OPENBOX_PID=$!

    x11vnc \
        -display "${DISPLAY}" \
        -rfbport "${VNC_PORT}" \
        -nopw \
        -forever \
        -shared \
        -xkb \
        -noxrecord \
        -noxfixes \
        -noxdamage \
        -bg

    if [[ "${AUTOSTART_CURSOR:-1}" == "1" ]]; then
        sleep 2
        /usr/local/bin/cursor >> /tmp/cursor.log 2>&1 &
        echo "Cursor autostart: /usr/local/bin/cursor (log: /tmp/cursor.log)"
    fi

    echo "VNC: connect to port ${VNC_PORT} (on host: 127.0.0.1:${VNC_PORT})"
    echo "Screen: ${VNC_SCREEN} (VNC_WIDTH/VNC_HEIGHT/VNC_DEPTH or VNC_RESOLUTION)"
    echo "User: $(whoami), HOME=${HOME}, DISPLAY=${DISPLAY}"

    wait "${XVFB_PID}"
}

if [[ "$(id -u)" -eq 0 ]]; then
    ensure_profile_dirs
    chown -R app:app "${HOME}" 2>/dev/null || true
    if [[ "${CURSOR_AUTO_UPDATE:-0}" == "1" ]]; then
        /usr/local/bin/update-cursor.sh || true
    fi
    exec gosu app:app /entrypoint.sh "$@"
fi

start_as_app
