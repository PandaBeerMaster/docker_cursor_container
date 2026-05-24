#!/bin/bash
# Точка входа для Cursor (workbench.externalBrowser) и ручного открытия OAuth-ссылок.

set -euo pipefail

# shellcheck source=load-app-session.sh
source /usr/local/lib/cursor-desktop/load-app-session.sh

url="${1:-}"
if [[ -z "${url}" ]]; then
    echo "usage: open-external-url <http(s)://...>" >&2
    exit 1
fi

if [[ "$(id -u)" -eq 0 ]]; then
    exec gosu app:app /usr/local/bin/open-external-url "${url}"
fi

# Только URL — chrome-wrapper распознаёт http(s) и запускает окно в фоне
exec /usr/local/bin/google-chrome-stable "${url}"
