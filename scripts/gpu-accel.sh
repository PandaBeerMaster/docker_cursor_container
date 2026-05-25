#!/bin/bash
# Опциональное видеоускорение (Intel/AMD VA-API через /dev/dri).
# Включение: GPU_ACCEL=1 в .env + devices/group_add в docker-compose.yml.

gpu_accel_enabled() {
    [[ "${GPU_ACCEL:-0}" == "1" ]] && [[ -e /dev/dri/renderD128 || -e /dev/dri/card0 ]]
}

apply_gpu_accel_env() {
    if ! gpu_accel_enabled; then
        return 0
    fi

    export LIBVA_DRIVERS_PATH="${LIBVA_DRIVERS_PATH:-/usr/lib/x86_64-linux-gnu/dri}"
    if [[ -z "${LIBVA_DRIVER_NAME:-}" ]] && command -v vainfo >/dev/null 2>&1; then
        if vainfo 2>/dev/null | grep -qi 'iHD\|Intel'; then
            export LIBVA_DRIVER_NAME=iHD
        elif vainfo 2>/dev/null | grep -qi 'radeonsi\|AMD'; then
            export LIBVA_DRIVER_NAME=radeonsi
        fi
    fi
}

chrome_gpu_args() {
    if ! gpu_accel_enabled; then
        echo --disable-gpu
        return 0
    fi
    cat <<'EOF'
--enable-gpu
--enable-gpu-rasterization
--use-gl=egl
--enable-features=VaapiVideoDecoder,VaapiIgnoreDriverChecks
EOF
}

cursor_gpu_args() {
    if ! gpu_accel_enabled; then
        return 0
    fi
    cat <<'EOF'
--enable-gpu-rasterization
--use-gl=egl
--enable-features=VaapiVideoDecoder,VaapiIgnoreDriverChecks
EOF
}
