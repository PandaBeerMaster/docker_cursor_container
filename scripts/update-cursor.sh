#!/bin/bash
# Переустановка Cursor из локального .deb в образе (/packages/).
# Запуск: docker compose exec -u root <service> update-cursor.sh

set -euo pipefail

CURSOR_DEB="${CURSOR_DEB:-/packages/cursor_3.5.17_amd64.deb}"

if [[ "$(id -u)" -ne 0 ]]; then
    echo "update-cursor.sh: run as root (e.g. docker compose exec -u root ... update-cursor.sh)" >&2
    exit 1
fi

if [[ ! -f "${CURSOR_DEB}" ]]; then
    echo "update-cursor.sh: file not found: ${CURSOR_DEB}" >&2
    echo "Rebuild image with packages/cursor_3.5.17_amd64.deb or mount deb to ${CURSOR_DEB}" >&2
    exit 1
fi

echo "Installing Cursor from ${CURSOR_DEB}..."
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y "${CURSOR_DEB}"
echo "Cursor updated."
