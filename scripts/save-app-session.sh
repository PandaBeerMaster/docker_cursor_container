#!/bin/bash
# Сохраняет DISPLAY/DBUS/HOME для xdg-open, Chrome и docker compose exec.

set -euo pipefail

SESSION_FILE=/tmp/app-session.env
RUNTIME_DIR=/tmp/runtime-app

export DISPLAY="${DISPLAY:-:1}"
export HOME="${HOME:-/home/app}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-${RUNTIME_DIR}}"

mkdir -p "${XDG_RUNTIME_DIR}"
chmod 700 "${XDG_RUNTIME_DIR}" 2>/dev/null || true

cat > "${SESSION_FILE}" <<EOF
DISPLAY=${DISPLAY}
HOME=${HOME}
XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR}
DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS:-}
BROWSER=/usr/local/bin/open-external-url
CHROME_EXECUTABLE=/usr/local/bin/google-chrome-stable
EOF

chmod 644 "${SESSION_FILE}" 2>/dev/null || true
