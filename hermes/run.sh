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

# ── API server ────────────────────────────────────────────────────────
export API_SERVER_ENABLED=true
export API_SERVER_HOST=0.0.0.0
export API_SERVER_PORT=8642
export API_SERVER_KEY="${API_KEY}"
export API_SERVER_CORS_ORIGINS="${CORS_ORIGINS}"

# ── Dashboard ─────────────────────────────────────────────────────────
export HERMES_DASHBOARD=1
export HERMES_DASHBOARD_HOST=0.0.0.0
export HERMES_DASHBOARD_PORT=9119

# ── Extra env vars ────────────────────────────────────────────────────
if bashio::config.exists 'extra_env'; then
    for var in $(bashio::config 'extra_env|keys[]'); do
        name="$(bashio::config "extra_env[${var}].name")"
        value="$(bashio::config "extra_env[${var}].value")"
        export "${name}=${value}"
    done
fi

bashio::log.info "Starting Hermes Agent..."
exec hermes gateway run
