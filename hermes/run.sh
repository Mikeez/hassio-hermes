#!/usr/bin/env sh
set -eu

OPTIONS_FILE="/data/options.json"

if [ ! -f "$OPTIONS_FILE" ]; then
  echo "Missing $OPTIONS_FILE"
  exit 1
fi

API_ENABLED="$(python3 -c "import json;print(str(json.load(open('$OPTIONS_FILE')).get('api_server_enabled', True)).lower())")"
API_KEY="$(python3 -c "import json;print(json.load(open('$OPTIONS_FILE')).get('api_server_key',''))")"
DASHBOARD_ENABLED="$(python3 -c "import json;print(str(json.load(open('$OPTIONS_FILE')).get('dashboard_enabled', True)).lower())")"
DASHBOARD_INSECURE="$(python3 -c "import json;print(str(json.load(open('$OPTIONS_FILE')).get('dashboard_insecure', False)).lower())")"
CORS_ORIGINS="$(python3 -c "import json;print(json.load(open('$OPTIONS_FILE')).get('cors_origins','*'))")"

if [ "$API_ENABLED" = "true" ]; then
  export API_SERVER_ENABLED=true
  export API_SERVER_HOST=0.0.0.0
  export API_SERVER_PORT=8642
  export API_SERVER_CORS_ORIGINS="$CORS_ORIGINS"

  if [ -z "$API_KEY" ]; then
    echo "ERROR: api_server_key is required when API server is enabled."
    exit 1
  fi

  export API_SERVER_KEY="$API_KEY"
fi

if [ "$DASHBOARD_ENABLED" = "true" ]; then
  export HERMES_DASHBOARD=1
  export HERMES_DASHBOARD_HOST=0.0.0.0
  export HERMES_DASHBOARD_PORT=9119

  if [ "$DASHBOARD_INSECURE" = "true" ]; then
    export HERMES_DASHBOARD_INSECURE=1
  fi
fi

echo "Starting Hermes Agent gateway..."
exec hermes gateway run