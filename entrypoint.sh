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
    if [[ ! -x "${HOME}/.config/openbox/autostart" ]] \
        && [[ -x /etc/skel/.config/openbox/autostart ]]; then
        cp /etc/skel/.config/openbox/autostart "${HOME}/.config/openbox/autostart"
        chmod +x "${HOME}/.config/openbox/autostart"
    fi
}

configure_git() {
    if ! command -v git >/dev/null 2>&1; then
        return 0
    fi
    if [[ -n "${GIT_USER:-}" ]]; then
        git config --global user.name "${GIT_USER}"
    fi
    if [[ -n "${GIT_MAIL:-}" ]]; then
        git config --global user.email "${GIT_MAIL}"
    fi
}

log_gpu_accel() {
    if [[ "${GPU_ACCEL:-0}" != "1" ]]; then
        return 0
    fi
    if [[ -e /dev/dri/renderD128 || -e /dev/dri/card0 ]]; then
        echo "GPU_ACCEL=1: /dev/dri доступен"
        if command -v vainfo >/dev/null 2>&1; then
            vainfo 2>/dev/null | head -5 || true
        fi
    else
        echo "GPU_ACCEL=1: /dev/dri не найден — проверьте devices в docker-compose.yml" >&2
    fi
}

start_as_app() {
    ensure_profile_dirs
    configure_git
    log_gpu_accel

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

    export XKB_DEFAULT_MODEL="${XKB_MODEL:-pc105}"
    export XKB_DEFAULT_LAYOUT="${XKB_LAYOUT:-ru,us}"
    export XKB_DEFAULT_VARIANT="${XKB_VARIANT:-,winkeys}"
    export XKB_DEFAULT_OPTIONS="${XKB_OPTIONS:-grp:alt_shift_toggle,grp_led:scroll}"

    openbox &
    OPENBOX_PID=$!

    # Без -noxfixes: x11vnc опрашивает CLIPBOARD через XFixes.
    # setclipboard (по умолчанию): принимать буфер с VNC-клиента (хост → контейнер).
    x11vnc \
        -display "${DISPLAY}" \
        -rfbport "${VNC_PORT}" \
        -nopw \
        -forever \
        -shared \
        -xkb \
        -noxrecord \
        -noxdamage \
        -bg

    sleep 0.5
    /usr/local/bin/setup-vnc-clipboard.sh
    # x11vnc -xkb может сбросить раскладку — применяем снова после VNC
    /usr/local/bin/setup-vnc-input.sh

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
    if [[ -d /projects ]]; then
        chown -R app:app /projects 2>/dev/null || true
    fi
    if [[ "${CURSOR_AUTO_UPDATE:-0}" == "1" ]]; then
        /usr/local/bin/update-cursor.sh || true
    fi
    exec gosu app:app /entrypoint.sh "$@"
fi

start_as_app
