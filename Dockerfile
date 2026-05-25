# Cursor + Chrome + VNC на Debian Bookworm slim
# Документация: Документация/Описание-сервиса.md

FROM debian:bookworm-slim

ARG APP_UID=1000
ARG APP_GID=1000
# Имя .deb в каталоге packages/ (положите файл перед сборкой)
ARG CURSOR_DEB_FILE=cursor_3.5.17_amd64.deb

ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:1 \
    HOME=/home/app \
    VNC_PORT=9999 \
    VNC_WIDTH=1920 \
    VNC_HEIGHT=1080 \
    VNC_DEPTH=24 \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    XKB_LAYOUT=us,ru \
    XKB_OPTIONS=grp:alt_shift_toggle \
    BROWSER=/usr/local/bin/open-external-url \
    CHROME_EXECUTABLE=/usr/local/bin/google-chrome-stable

# --- Системные пакеты: X11, VNC, WM, зависимости Electron/Chrome ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    wget \
    gnupg \
    gosu \
    dbus-x11 \
    xvfb \
    x11vnc \
    openbox \
    xterm \
    autocutsel \
    xclip \
    x11-xserver-utils \
    xkb-data \
    locales \
    fontconfig \
    fonts-dejavu-core \
    fonts-liberation \
    fonts-noto-core \
    libgtk-3-0 \
    libnotify4 \
    libnss3 \
    libxss1 \
    libasound2 \
    libgbm1 \
    libdrm2 \
    libxkbcommon0 \
    libatk-bridge2.0-0 \
    libatspi2.0-0 \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxi6 \
    libxrandr2 \
    libpango-1.0-0 \
    libcairo2 \
    libgdk-pixbuf-2.0-0 \
    xdg-utils \
    jq \
    git \
    bash-completion \
    openssh-client \
    libva2 \
    vainfo \
    mesa-va-drivers \
    va-driver-all \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i \
        -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' \
        -e 's/# ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' \
        /etc/locale.gen \
    && locale-gen

# libvncserver 0.9.15: исправление буфера обмена хост → VNC (ExtendedClipboard UTF-8, PR #639)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    build-essential \
    cmake \
    pkg-config \
    zlib1g-dev \
    libjpeg-dev \
    libpng-dev \
    liblzo2-dev \
    libssl-dev \
    && curl -fsSL -o /tmp/libvncserver.tar.gz \
        https://github.com/LibVNC/libvncserver/archive/refs/tags/LibVNCServer-0.9.15.tar.gz \
    && mkdir -p /tmp/libvncserver-src /tmp/libvncserver-build \
    && tar xzf /tmp/libvncserver.tar.gz -C /tmp/libvncserver-src --strip-components=1 \
    && cmake -S /tmp/libvncserver-src -B /tmp/libvncserver-build \
        -DCMAKE_BUILD_TYPE=MinSizeRel \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_INSTALL_LIBDIR=lib/x86_64-linux-gnu \
        -DBUILD_SHARED_LIBS=ON \
        -DWITH_EXAMPLES=OFF \
        -DWITH_TESTS=OFF \
        -DWITH_SDL=OFF \
        -DWITH_GTK=OFF \
    && cmake --build /tmp/libvncserver-build -j"$(nproc)" \
    && cmake --install /tmp/libvncserver-build \
    && ldconfig \
    && rm -rf /tmp/libvncserver.tar.gz /tmp/libvncserver-src /tmp/libvncserver-build \
    && apt-get purge -y --auto-remove \
        build-essential cmake pkg-config \
        zlib1g-dev libjpeg-dev libpng-dev liblzo2-dev libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# --- Google Chrome (официальный репозиторий) ---
RUN install -d -m 0755 /usr/share/keyrings \
    && wget -qO- https://dl.google.com/linux/linux_signing_key.pub \
        | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" \
        > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends google-chrome-stable \
    && rm -rf /var/lib/apt/lists/* \
    && if [ -f /usr/share/applications/google-chrome.desktop ]; then \
        sed -i 's|Exec=/usr/bin/google-chrome-stable|Exec=/usr/local/bin/google-chrome-stable|g' \
            /usr/share/applications/google-chrome.desktop; \
    fi

# --- Cursor (локальный .deb из packages/, без скачивания из интернета) ---
COPY packages/ /packages/
RUN apt-get update \
    && apt-get install -y "/packages/${CURSOR_DEB_FILE}" \
    && rm -rf /var/lib/apt/lists/*

# --- Скрипты ---
COPY entrypoint.sh /entrypoint.sh
COPY scripts/update-cursor.sh /usr/local/bin/update-cursor.sh
COPY scripts/chrome-wrapper.sh /usr/local/bin/google-chrome-stable
COPY scripts/cursor-wrapper.sh /usr/local/bin/cursor
COPY scripts/xdg-open.sh /usr/local/bin/xdg-open
COPY scripts/setup-default-browser.sh /usr/local/bin/setup-default-browser.sh
COPY scripts/save-app-session.sh /usr/local/bin/save-app-session.sh
COPY scripts/load-app-session.sh /usr/local/lib/cursor-desktop/load-app-session.sh
COPY scripts/open-external-url.sh /usr/local/bin/open-external-url
COPY scripts/cleanup-chrome-locks.sh /usr/local/bin/cleanup-chrome-locks.sh
COPY scripts/setup-vnc-input.sh /usr/local/bin/setup-vnc-input.sh
COPY scripts/setup-vnc-clipboard.sh /usr/local/bin/setup-vnc-clipboard.sh
COPY scripts/gpu-accel.sh /usr/local/bin/gpu-accel.sh
COPY config/profile.d/cursor-desktop.sh /etc/profile.d/cursor-desktop.sh
COPY config/inputrc /etc/inputrc.d/cursor-desktop

RUN chmod +x /entrypoint.sh /usr/local/bin/update-cursor.sh \
        /usr/local/bin/google-chrome-stable /usr/local/bin/cursor \
        /usr/local/bin/xdg-open /usr/local/bin/setup-default-browser.sh \
        /usr/local/bin/save-app-session.sh /usr/local/bin/open-external-url \
        /usr/local/bin/cleanup-chrome-locks.sh \
        /usr/local/bin/setup-vnc-input.sh \
        /usr/local/bin/setup-vnc-clipboard.sh \
        /usr/local/bin/gpu-accel.sh \
        /usr/local/lib/cursor-desktop/load-app-session.sh \
    && ln -sf /usr/local/bin/open-external-url /usr/local/bin/sensible-browser \
    && ln -sf /usr/local/bin/google-chrome-stable /usr/local/bin/www-browser \
    && if [ -f /usr/bin/cursor ] && head -c 2 /usr/bin/cursor | grep -q '^#'; then \
        mv /usr/bin/cursor /usr/bin/cursor.deb-shim; \
        ln -sf /usr/local/bin/cursor /usr/bin/cursor; \
    fi \
    && if [ -f /usr/bin/xdg-open ]; then \
        mv /usr/bin/xdg-open /usr/bin/xdg-open.debian; \
    fi \
    && update-alternatives --install /usr/bin/x-www-browser x-www-browser \
        /usr/local/bin/open-external-url 200 \
    && update-alternatives --set x-www-browser /usr/local/bin/open-external-url \
    && chmod +x /etc/profile.d/cursor-desktop.sh \
    && grep -q 'inputrc.d/cursor-desktop' /etc/inputrc 2>/dev/null \
        || echo '$include /etc/inputrc.d/cursor-desktop' >> /etc/inputrc

# --- Пользователь без root (UID/GID настраиваются при сборке) ---
RUN groupadd -g "${APP_GID}" app \
    && useradd -m -u "${APP_UID}" -g app -s /bin/bash app \
    && usermod -aG video,render app 2>/dev/null || usermod -aG video app \
    && mkdir -p /home/app/.config /home/app/.cursor \
    && chown -R app:app /home/app

WORKDIR /home/app

# По умолчанию root: entrypoint выравнивает права на тома и переключается на app через gosu.
# В compose можно задать user: "1000:1000" — тогда entrypoint сразу работает от app.

EXPOSE 9999

ENTRYPOINT ["/entrypoint.sh"]
