# Hermes Agent Add-on Documentation

Runs [Hermes Agent](https://hermes-agent.nousresearch.com/) by NousResearch inside Home Assistant OS. Hermes is an autonomous agent framework that exposes an OpenAI-compatible API gateway and an optional web dashboard.

## Configuration

### `api_server_enabled` (bool, default: `true`)

Enables the OpenAI-compatible API server on port 8642.

### `api_server_key` (password, required when API enabled)

Bearer token used to authenticate API requests. Must not be empty when the API server is enabled.

### `dashboard_enabled` (bool, default: `true`)

Enables the Hermes web dashboard on port 9119.

### `dashboard_insecure` (bool, default: `false`)

Set to `true` to allow unauthenticated access to the dashboard. Not recommended for production use.

### `cors_origins` (string, default: `*`)

Comma-separated list of allowed CORS origins for the API server. Use `*` to allow all origins or restrict to specific domains.

### `extra_env` (list, optional)

Additional environment variables to pass into Hermes. Each entry has `name` and `value` fields.

```yaml
extra_env:
  - name: SOME_VAR
    value: some_value
```

## Ports

| Port | Protocol | Description |
|------|----------|-------------|
| 8642 | TCP | Hermes Gateway / OpenAI-compatible API |
| 9119 | TCP | Hermes Dashboard |

## Data persistence

Hermes stores all agent data under `/data/hermes` inside the add-on container, which maps to the Home Assistant persistent data volume. Data survives add-on restarts and updates.

## Support

- [Hermes Agent docs](https://hermes-agent.nousresearch.com/docs/)
- [GitHub repository](https://github.com/mikeez/hassio-hermes)
