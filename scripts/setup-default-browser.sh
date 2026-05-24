#!/bin/bash
# Регистрация Google Chrome как браузера по умолчанию (Sign in / Sign up в Cursor).

set -euo pipefail

# shellcheck source=load-app-session.sh
source /usr/local/lib/cursor-desktop/load-app-session.sh

BROWSER_BIN="/usr/local/bin/open-external-url"
CHROME_BIN="/usr/local/bin/google-chrome-stable"
DESKTOP_ID="cursor-desktop-chrome.desktop"

mkdir -p \
    "${HOME}/.config" \
    "${HOME}/.local/share/applications"

cat > "${HOME}/.local/share/applications/${DESKTOP_ID}" <<EOF
[Desktop Entry]
Version=1.0
Name=Google Chrome (Cursor Desktop)
GenericName=Web Browser
Exec=${CHROME_BIN} %U
Terminal=false
Type=Application
MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
Categories=Network;WebBrowser;
StartupNotify=true
EOF

cat > "${HOME}/.config/mimeapps.list" <<EOF
[Default Applications]
x-scheme-handler/http=${DESKTOP_ID}
x-scheme-handler/https=${DESKTOP_ID}
text/html=${DESKTOP_ID}
application/xhtml+xml=${DESKTOP_ID}

[Added Associations]
EOF

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "${HOME}/.local/share/applications" 2>/dev/null || true
fi

if command -v xdg-settings >/dev/null 2>&1; then
    xdg-settings set default-web-browser "${DESKTOP_ID}" 2>/dev/null || true
fi
if command -v xdg-mime >/dev/null 2>&1; then
    xdg-mime default "${DESKTOP_ID}" x-scheme-handler/http 2>/dev/null || true
    xdg-mime default "${DESKTOP_ID}" x-scheme-handler/https 2>/dev/null || true
fi

SETTINGS_DIR="${HOME}/.config/Cursor/User"
SETTINGS_FILE="${SETTINGS_DIR}/settings.json"
mkdir -p "${SETTINGS_DIR}"

browser_json="\"workbench.externalBrowser\": \"${BROWSER_BIN}\""

if [[ ! -f "${SETTINGS_FILE}" ]]; then
    cat > "${SETTINGS_FILE}" <<EOF
{
  ${browser_json}
}
EOF
elif command -v jq >/dev/null 2>&1; then
    tmp=$(mktemp)
    jq --arg b "${BROWSER_BIN}" '.["workbench.externalBrowser"] = $b' "${SETTINGS_FILE}" > "${tmp}"
    mv "${tmp}" "${SETTINGS_FILE}"
else
    if ! grep -q 'workbench.externalBrowser' "${SETTINGS_FILE}" 2>/dev/null; then
        sed -i "1 s/^{/{\n  ${browser_json},/" "${SETTINGS_FILE}" 2>/dev/null || true
    fi
fi

echo "Default browser: ${BROWSER_BIN}"
