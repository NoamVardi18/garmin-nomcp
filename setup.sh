#!/bin/sh
# Rebuild the venv from scratch. Safe to re-run; takes ~20s.
#
# garminconnect is pinned to 0.3.2 deliberately: that is the version the MCP
# server actually resolves to, and several tools (schedule_week, set_heart_rate_zones)
# call `client.post` / `client.request` directly, which 0.3.x reshuffled. Newer
# is not better here - it is untested against these 148 tools.
set -e
cd "$(dirname "$0")"
uv venv --python 3.12 .venv
uv pip install --python .venv/bin/python "garmin-mcp @ git+https://github.com/Taxuspt/garmin_mcp"
uv pip install --python .venv/bin/python "garminconnect==0.3.2"
.venv/bin/python test_garmin.py
