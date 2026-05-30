#!/usr/bin/env bashio
set -e

# ── Options ──────────────────────────────────────────────────────────
API_KEY="$(bashio::config 'api_key')"
CORS_ORIGINS="$(bashio::config 'cors_origins')"

if bashio::var.is_empty "${API_KEY}"; then
    bashio::exit.nok "api_key must not be empty."
fi

# ── Persistent data ───────────────────────────────────────────────────
mkdir -p /config/hermes
export HERMES_DATA_DIR=/config/hermes

# ── Hermes environment ────────────────────────────────────────────────
export API_SERVER_ENABLED=true
export API_SERVER_HOST=127.0.0.1
export API_SERVER_PORT=8642
export API_SERVER_KEY="${API_KEY}"
export API_SERVER_CORS_ORIGINS="${CORS_ORIGINS}"

export HERMES_DASHBOARD=1
export HERMES_DASHBOARD_HOST=127.0.0.1
export HERMES_DASHBOARD_PORT=9119

# ── Extra env vars ────────────────────────────────────────────────────
if bashio::config.exists 'extra_env'; then
    for var in $(bashio::config 'extra_env|keys[]'); do
        name="$(bashio::config "extra_env[${var}].name")"
        value="$(bashio::config "extra_env[${var}].value")"
        export "${name}=${value}"
    done
fi

# ── Graceful shutdown ─────────────────────────────────────────────────
NGINX_PID=""
HERMES_PID=""

cleanup() {
    bashio::log.info "Shutting down..."
    [ -n "${HERMES_PID}" ] && kill "${HERMES_PID}" 2>/dev/null || true
    [ -n "${NGINX_PID}" ]  && kill "${NGINX_PID}"  2>/dev/null || true
    wait
}
trap cleanup SIGTERM SIGINT

# ── Start nginx ───────────────────────────────────────────────────────
bashio::log.info "Starting nginx..."
nginx &
NGINX_PID=$!

# ── Start Hermes ──────────────────────────────────────────────────────
bashio::log.info "Starting Hermes Agent..."
hermes gateway run &
HERMES_PID=$!

# ── Wait ──────────────────────────────────────────────────────────────
wait "${HERMES_PID}"
bashio::log.warning "Hermes exited — stopping add-on."
kill "${NGINX_PID}" 2>/dev/null || true
