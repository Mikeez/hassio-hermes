ARG BUILD_FROM
FROM ${BUILD_FROM}

# ── System dependencies ──────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        git nginx tmux rsync \
        python3 python3-pip python3-venv \
        build-essential python3-dev libffi-dev \
        jq curl \
        ripgrep \
        chromium \
        sqlite3 libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

ENV PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/chromium

# ── Node.js 22 ───────────────────────────────────────────────────────
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g agent-browser

# ── uv ───────────────────────────────────────────────────────────────
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
ENV UV_LINK_MODE=copy

# ── ttyd (compiled from source for glibc forkpty) ────────────────────
ARG TTYD_VERSION=1.7.7
RUN apt-get update && apt-get install -y --no-install-recommends \
        cmake libjson-c-dev libwebsockets-dev \
    && git clone --branch "${TTYD_VERSION}" --depth 1 \
        https://github.com/tsl0922/ttyd.git /tmp/ttyd \
    && cd /tmp/ttyd && mkdir build && cd build \
    && cmake .. -DCMAKE_BUILD_TYPE=Release \
    && make -j"$(nproc)" && make install \
    && rm -rf /tmp/ttyd \
    && apt-get purge -y cmake \
    && apt-get autoremove -y && rm -rf /var/lib/apt/lists/* \
    && ttyd --version

# ── nginx static pages + full proxy config ────────────────────────────
RUN mkdir -p /var/www /var/log/nginx /run/nginx
COPY landing.html loading.html /var/www/
COPY nginx.conf /etc/nginx/nginx.full.conf

# ── Add-on support scripts ────────────────────────────────────────────
COPY dashboard-patches.py /usr/local/bin/hermes-dashboard-patches
RUN chmod +x /usr/local/bin/hermes-dashboard-patches

# ── Runtime home → /config (persistent HA add-on storage) ────────────
ENV HOME=/config

# ── Add-on entrypoint ────────────────────────────────────────────────
COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
