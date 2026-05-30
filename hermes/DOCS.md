# Hermes Agent

Runs [Hermes Agent](https://hermes-agent.nousresearch.com/) by NousResearch inside Home Assistant. Hermes is a self-improving autonomous agent with a built-in learning loop, skill creation, and an OpenAI-compatible API.

The dashboard is accessible directly from your HA sidebar via the built-in ingress tunnel — no port forwarding required.

## Configuration

### `api_key` (password, required)

Bearer token used to authenticate API requests. Must not be empty.

### `cors_origins` (string, default: `*`)

Allowed CORS origins for the OpenAI-compatible API. Use `*` to allow all, or restrict to specific origins.

### `extra_env` (list, optional)

Additional environment variables passed to Hermes. Useful for setting LLM provider API keys.

```yaml
extra_env:
  - name: OPENAI_API_KEY
    value: sk-...
  - name: OPENROUTER_API_KEY
    value: sk-or-...
```

## Ports

| Port | Description |
|------|-------------|
| 9119 | Dashboard (via HA ingress — no external port needed) |
| 8642 | OpenAI-compatible API (optional, disabled by default) |

## Data persistence

All agent data is stored in `/config/hermes`, which maps to Home Assistant's persistent config volume. Data survives restarts and updates.

## Support

- [Hermes Agent docs](https://hermes-agent.nousresearch.com/docs/)
- [GitHub repository](https://github.com/mikeez/hassio-hermes)
