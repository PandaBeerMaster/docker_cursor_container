#!/bin/bash
# Запуск Cursor: обход /usr/bin/cursor (скрипт с вопросом про WSL) → прямой ELF из /usr/share/cursor/

set -euo pipefail

# shellcheck source=gpu-accel.sh
source /usr/local/bin/gpu-accel.sh

export DISPLAY="${DISPLAY:-:1}"
export HOME="${HOME:-/home/app}"

apply_gpu_accel_env

CURSOR_EXTRA_ARGS=()
while IFS= read -r flag; do
    [[ -n "${flag}" ]] && CURSOR_EXTRA_ARGS+=("${flag}")
done < <(cursor_gpu_args)

# Docker Desktop на Windows часто пробрасывает WSL-переменные — Cursor показывает диалог
unset WSL_DISTRO_NAME WSL_INTEROP WSLENV 2>/dev/null || true
export DONT_PROMPT_WSL_INSTALL=1

is_elf_binary() {
    local path=$1
    [[ -f "${path}" && -x "${path}" ]] || return 1
    local sig
    sig=$(head -c 4 "${path}" 2>/dev/null | od -An -tx1 | tr -d ' \n')
    [[ "${sig}" == "7f454c46" ]]
}

find_cursor_binary() {
    local candidate
    for candidate in \
        /usr/share/cursor/cursor \
        /usr/share/cursor/bin/cursor; do
        if is_elf_binary "${candidate}"; then
            echo "${candidate}"
            return 0
        fi
    done
    if command -v dpkg >/dev/null 2>&1; then
        while IFS= read -r candidate; do
            if is_elf_binary "${candidate}"; then
                echo "${candidate}"
                return 0
            fi
        done < <(dpkg -L cursor 2>/dev/null | grep -E '/usr/share/cursor/' || true)
    fi
    return 1
}

CURSOR_BIN=$(find_cursor_binary) || {
    echo "cursor: ELF binary not found under /usr/share/cursor/" >&2
    exit 1
}

CURSOR_BASE_ARGS=(
    --no-sandbox
    --disable-gpu-sandbox
    --disable-dev-shm-usage
)
if ! gpu_accel_enabled; then
    CURSOR_BASE_ARGS+=(--disable-gpu)
fi

exec "${CURSOR_BIN}" \
    "${CURSOR_BASE_ARGS[@]}" \
    "${CURSOR_EXTRA_ARGS[@]}" \
    "$@"
