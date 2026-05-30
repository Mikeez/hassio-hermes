ARG BUILD_FROM
FROM ${BUILD_FROM}

# ── System dependencies ──────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        git nginx \
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

# ── nginx static pages + full proxy config ────────────────────────────
RUN mkdir -p /var/www /var/log/nginx /run/nginx
COPY landing.html loading.html /var/www/
COPY nginx.conf /etc/nginx/nginx.full.conf

# ── Add-on support scripts ────────────────────────────────────────────
COPY dashboard-patches.py /usr/local/bin/hermes-dashboard-patches
RUN chmod +x /usr/local/bin/hermes-dashboard-patches

# ── Add-on entrypoint ────────────────────────────────────────────────
COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
