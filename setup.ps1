# Windows setup, twin of setup.sh. Run from PowerShell:
#
#   .\setup.ps1              full install
#   .\setup.ps1 -Slim        skip the `mcp` package (~30 MB smaller, see below)
#
# garminconnect is pinned to 0.3.2 deliberately: that is the version the MCP
# server itself resolves to, and several tools (schedule_week, set_heart_rate_zones)
# call client.post / client.request directly, a surface 0.3.x reshuffled.
param([switch]$Slim)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$mcpSpec = "garmin-mcp @ git+https://github.com/Taxuspt/garmin_mcp"

# Find a Python 3.12+. The `py` launcher ships with the python.org installer.
$python = $null
foreach ($candidate in @("py -3.12", "py -3", "python")) {
    $exe, $flag = $candidate -split " ", 2
    if (Get-Command $exe -ErrorAction SilentlyContinue) { $python = $candidate; break }
}
if (-not $python) { throw "No Python found. Install Python 3.12 from python.org and re-run." }

Write-Host "Creating virtualenv with: $python"
Invoke-Expression "$python -m venv .venv"

$venvPy = Join-Path $PSScriptRoot ".venv\Scripts\python.exe"
& $venvPy -m pip install --quiet --upgrade pip
& $venvPy -m pip install --quiet $mcpSpec
& $venvPy -m pip install --quiet "garminconnect==0.3.2"

if ($Slim) {
    # `mcp` is imported by garmin_mcp/__init__.py and never used by anything this
    # script calls, so garmin.py stubs it when absent. Dropping it also drops
    # pydantic, starlette, uvicorn and friends.
    Write-Host "Slim: removing the unused mcp dependency tree"
    & $venvPy -m pip uninstall --quiet --yes mcp pydantic pydantic-core pydantic-settings `
        anyio jsonschema jsonschema-specifications referencing rpds-py attrs click `
        sse-starlette starlette uvicorn httpx httpx-sse httpcore h11 python-multipart 2>$null
}

& $venvPy test_garmin.py
Write-Host ""
Write-Host "Done. Use:  .\garmin.cmd doctor"
