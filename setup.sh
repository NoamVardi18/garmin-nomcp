#!/bin/sh
# Rebuild the venv from scratch. Safe to re-run; takes ~20s with uv, ~60s with pip.
#
# garminconnect is pinned to 0.3.2 deliberately: that is the version the MCP
# server actually resolves to, and several tools (schedule_week, set_heart_rate_zones)
# call `client.post` / `client.request` directly, which 0.3.x reshuffled. Newer
# is not better here - it is untested against these 148 tools.
set -e
cd "$(dirname "$0")"

MCP="garmin-mcp @ git+https://github.com/Taxuspt/garmin_mcp"

if command -v uv >/dev/null 2>&1; then
  uv venv --python 3.12 .venv
  uv pip install --python .venv/bin/python "$MCP"
  uv pip install --python .venv/bin/python "garminconnect==0.3.2"
else
  # No uv (a plain VPS, a CI box). Stdlib venv + pip gets to the same place.
  python3 -m venv .venv
  .venv/bin/pip -q install --upgrade pip
  .venv/bin/pip -q install "$MCP"
  .venv/bin/pip -q install "garminconnect==0.3.2"
fi

.venv/bin/python test_garmin.py
