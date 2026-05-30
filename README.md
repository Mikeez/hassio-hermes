# Hermes Add-ons for Home Assistant

[![Add repository to HA](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https://github.com/mikeez/hassio-hermes)

This repository provides Home Assistant add-ons for [Hermes Agent](https://hermes-agent.nousresearch.com/) by NousResearch.

## Add-ons

### Hermes Agent

Runs the Hermes autonomous agent gateway inside Home Assistant OS. Exposes an OpenAI-compatible API and an optional web dashboard.

| Port | Purpose |
|------|---------|
| 8642 | Hermes Gateway / OpenAI-compatible API |
| 9119 | Hermes Dashboard |

See [hermes/DOCS.md](hermes/DOCS.md) for full configuration documentation.

## Installation

1. In Home Assistant, go to **Settings → Add-ons → Add-on Store**
2. Click the menu (⋮) in the top-right and choose **Repositories**
3. Add `https://github.com/mikeez/hassio-hermes`
4. Find **Hermes Agent** in the store and install it
