#!/command/with-contenv bash
set -euo pipefail

# ── Options ───────────────────────────────────────────────────────────
OPTIONS_FILE="/data/options.json"
if [ ! -f "$OPTIONS_FILE" ]; then
    echo "[run] FATAL: $OPTIONS_FILE not found"
    exit 1
fi

opt()      { jq -r ".${1} // empty" "$OPTIONS_FILE"; }
opt_bool() { jq -r ".${1} // false" "$OPTIONS_FILE"; }

GIT_URL=$(opt git_url)
GIT_REF=$(opt git_ref)
GIT_TOKEN=$(opt git_token)
AUTO_UPDATE=$(opt_bool auto_update)
API_KEY=$(opt api_key)
CORS_ORIGINS=$(opt cors_origins)

# ── Persistent paths ──────────────────────────────────────────────────
HERMES_BASE="/config/.hermes"
SRC_DIR="$HERMES_BASE/hermes-agent"
VENV_DIR="$SRC_DIR/venv"
MARKER_FILE="$HERMES_BASE/.install-marker"
INGRESS_PORT=49268

mkdir -p "$HERMES_BASE"

# ── Start nginx with loading page (shown while Hermes installs) ───────
cat > /etc/nginx/nginx.conf << LOADCONF
worker_processes 1;
pid /var/run/nginx.pid;
error_log stderr warn;
events { worker_connections 64; }
http {
    server {
        listen ${INGRESS_PORT};
        location / { root /var/www; try_files /loading.html =404; add_header Cache-Control "no-cache"; }
        location = /health { return 200 "OK\n"; add_header Content-Type text/plain; }
    }
}
LOADCONF
nginx
echo "[run] Loading page active on port $INGRESS_PORT"

# ── Clone Hermes ──────────────────────────────────────────────────────
if [ ! -d "$SRC_DIR/.git" ]; then
    echo "[run] Cloning Hermes Agent from $GIT_URL ..."
    CLONE_URL="$GIT_URL"
    if [ -n "$GIT_TOKEN" ]; then
        CLONE_URL=$(echo "$GIT_URL" | sed "s|https://|https://${GIT_TOKEN}@|")
    fi
    CLONE_ARGS=()
    [ -n "$GIT_REF" ] && CLONE_ARGS+=(--branch "$GIT_REF")
    git clone "${CLONE_ARGS[@]}" "$CLONE_URL" "$SRC_DIR"
    cd "$SRC_DIR" && git submodule update --init --recursive 2>/dev/null || true
    echo "[run] Clone complete: $(cd "$SRC_DIR" && git log --oneline -1)"
fi

# ── Auto-update ───────────────────────────────────────────────────────
if [ "$AUTO_UPDATE" = "true" ]; then
    echo "[run] Pulling latest changes..."
    cd "$SRC_DIR"
    git stash --quiet 2>/dev/null || true
    git pull --ff-only 2>/dev/null || echo "[run] Warning: git pull failed"
    git stash pop --quiet 2>/dev/null || true
    git submodule update --init --recursive 2>/dev/null || true
fi

# ── Install with marker-file cache ───────────────────────────────────
compute_marker() {
    local hash
    hash="$(cd "$SRC_DIR" && git rev-parse HEAD 2>/dev/null || echo none)"
    echo "${GIT_URL}|${GIT_REF}|${hash}"
}

install_needed() {
    [ ! -f "$MARKER_FILE" ]                              && return 0
    [ "$(cat "$MARKER_FILE")" != "$(compute_marker)" ]  && return 0
    [ ! -f "$VENV_DIR/bin/hermes" ]                     && return 0
    return 1
}

if [ ! -f "$VENV_DIR/bin/activate" ]; then
    echo "[run] Creating venv..."
    uv venv "$VENV_DIR" --python python3
fi
# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"

if install_needed; then
    echo "[run] Installing Hermes (this takes a few minutes on first run)..."
    cd "$SRC_DIR"
    uv pip install -e ".[all]" 2>&1 | tail -5
    for sub in mini-swe-agent tinker-atropos; do
        [ -f "$SRC_DIR/$sub/pyproject.toml" ] && uv pip install -e "$SRC_DIR/$sub" 2>&1 | tail -3
    done
    compute_marker > "$MARKER_FILE"
    echo "[run] Install complete"
else
    echo "[run] Hermes install up to date (skipping)"
fi

# ── Validate ──────────────────────────────────────────────────────────
if [ -z "$API_KEY" ]; then
    echo "[run] FATAL: api_key must not be empty"
    exit 1
fi

HERMES_VERSION=$(hermes --version 2>/dev/null | head -1 || echo "unknown")
echo "[run] Hermes version: $HERMES_VERSION"

# ── Environment ───────────────────────────────────────────────────────
export API_SERVER_ENABLED=true
export API_SERVER_HOST=127.0.0.1
export API_SERVER_PORT=8642
export API_SERVER_KEY="$API_KEY"
export API_SERVER_CORS_ORIGINS="${CORS_ORIGINS:-*}"
export HERMES_DASHBOARD=1
export HERMES_DASHBOARD_HOST=127.0.0.1
export HERMES_DASHBOARD_PORT=9119
export HERMES_DATA_DIR="$HERMES_BASE/data"

mkdir -p "$HERMES_DATA_DIR"

# Extra env vars
ENV_COUNT=$(jq '.extra_env | length' "$OPTIONS_FILE" 2>/dev/null || echo 0)
for i in $(seq 0 $((ENV_COUNT - 1))); do
    VAR_NAME=$(jq -r ".extra_env[$i].name" "$OPTIONS_FILE")
    VAR_VALUE=$(jq -r ".extra_env[$i].value" "$OPTIONS_FILE")
    [ -n "$VAR_VALUE" ] && export "${VAR_NAME}=${VAR_VALUE}"
done

# ── Switch nginx to full proxy config ─────────────────────────────────
cp /etc/nginx/nginx.full.conf /etc/nginx/nginx.conf
nginx -s reload
echo "[run] nginx switched to full config"

# ── Graceful shutdown ─────────────────────────────────────────────────
GATEWAY_PID=""

cleanup() {
    echo "[run] Shutting down..."
    nginx -s quit 2>/dev/null || true
    [ -n "$GATEWAY_PID" ] && kill -TERM "$GATEWAY_PID" 2>/dev/null || true
    wait
    exit 0
}
trap cleanup SIGTERM SIGINT

# ── Start Hermes gateway ──────────────────────────────────────────────
start_gateway() {
    cd "$HERMES_BASE"
    hermes gateway run &
    GATEWAY_PID=$!
    echo "[run] Gateway started (PID: $GATEWAY_PID)"
}

start_gateway

echo "─────────────────────────────────────────────"
echo " $HERMES_VERSION"
echo " Gateway: http://127.0.0.1:8642"
echo " Dashboard: http://127.0.0.1:9119"
echo "─────────────────────────────────────────────"

# ── Supervisor loop ───────────────────────────────────────────────────
while true; do
    if ! kill -0 "$GATEWAY_PID" 2>/dev/null; then
        wait "$GATEWAY_PID" 2>/dev/null || true
        echo "[run] Gateway exited — restarting in 3s..."
        sleep 3
        start_gateway
    fi
    sleep 5
done
