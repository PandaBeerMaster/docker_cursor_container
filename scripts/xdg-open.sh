#!/bin/bash
# Cursor вызывает xdg-open для входа — перенаправляем в open-external-url.

# shellcheck source=load-app-session.sh
source /usr/local/lib/cursor-desktop/load-app-session.sh

for arg in "$@"; do
    case "${arg}" in
        http://* | https://*)
            exec /usr/local/bin/open-external-url "${arg}"
            ;;
    esac
done

if [[ -x /usr/bin/xdg-open.debian ]]; then
    exec /usr/bin/xdg-open.debian "$@"
fi

exec /usr/bin/xdg-open "$@"
