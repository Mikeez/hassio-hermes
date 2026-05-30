#!/usr/bin/env sh
# cont-init.d script: reads HA options.json and exports config into the
# s6 container environment so main-hermes and dashboard pick it up.
set -eu

OPTIONS_FILE="/data/options.json"
ENV_DIR="/var/run/s6/container_environment"

if [ ! -f "$OPTIONS_FILE" ]; then
  echo "[ha-options] $OPTIONS_FILE not found; using Hermes defaults."
  exit 0
fi

json_get() {
  python3 -c "
import json, sys
d = json.load(open('$OPTIONS_FILE'))
v = d.get('$1', $2)
print(str(v).lower() if isinstance(v, bool) else v)
"
}

mkdir -p "$ENV_DIR"

API_ENABLED="$(json_get api_server_enabled True)"
API_KEY="$(json_get api_server_key '')"
DASHBOARD_ENABLED="$(json_get dashboard_enabled True)"
DASHBOARD_INSECURE="$(json_get dashboard_insecure False)"
CORS_ORIGINS="$(json_get cors_origins '*')"

if [ "$API_ENABLED" = "true" ]; then
  if [ -z "$API_KEY" ]; then
    echo "[ha-options] ERROR: api_server_key must not be empty when API server is enabled."
    exit 1
  fi
  printf '%s' "true"          > "$ENV_DIR/API_SERVER_ENABLED"
  printf '%s' "0.0.0.0"      > "$ENV_DIR/API_SERVER_HOST"
  printf '%s' "8642"         > "$ENV_DIR/API_SERVER_PORT"
  printf '%s' "$API_KEY"     > "$ENV_DIR/API_SERVER_KEY"
  printf '%s' "$CORS_ORIGINS" > "$ENV_DIR/API_SERVER_CORS_ORIGINS"
fi

if [ "$DASHBOARD_ENABLED" = "true" ]; then
  printf '%s' "1"       > "$ENV_DIR/HERMES_DASHBOARD"
  printf '%s' "0.0.0.0" > "$ENV_DIR/HERMES_DASHBOARD_HOST"
  printf '%s' "9119"    > "$ENV_DIR/HERMES_DASHBOARD_PORT"
  [ "$DASHBOARD_INSECURE" = "true" ] && printf '%s' "1" > "$ENV_DIR/HERMES_DASHBOARD_INSECURE"
fi

echo "[ha-options] Configuration applied."
