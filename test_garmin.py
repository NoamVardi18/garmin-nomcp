#!/usr/bin/env python3
"""Self-check: run `.venv/bin/python test_garmin.py`.

Offline checks cover the argument parsing and tool harvesting (the parts with
branches worth breaking). The live check is last and needs valid tokens.
"""

import garmin


def test_arg_parsing():
    def sample(date: str, limit: int = 5, verbose: bool = False, tags: list = None):
        pass

    args, kwargs = garmin._parse_args(sample, ["2026-09-04", "10"])
    assert args == ["2026-09-04", 10], args  # date stays str, limit becomes int

    args, kwargs = garmin._parse_args(sample, ["--date=2026-09-04", "--limit", "3"])
    assert kwargs == {"date": "2026-09-04", "limit": 3}, kwargs

    # dashes in flags map to underscores in parameter names
    def dated(start_date: str):
        pass

    _, kwargs = garmin._parse_args(dated, ["--start-date", "2026-09-04"])
    assert kwargs == {"start_date": "2026-09-04"}, kwargs

    # a bare --flag with no value is a boolean true
    _, kwargs = garmin._parse_args(sample, ["--verbose"])
    assert kwargs == {"verbose": True}, kwargs

    # JSON-shaped values decode; a str-annotated one never does
    assert garmin._coerce("[1,2]", list) == [1, 2]
    assert garmin._coerce("2026-09-04", str) == "2026-09-04"
    assert garmin._coerce("42", str) == "42"


def test_unwrap():
    assert garmin._unwrap('{"a": 1}') == {"a": 1}
    assert garmin._unwrap("not json") == "not json"
    assert garmin._unwrap({"a": 1}) == {"a": 1}


def test_collector_matches_mcp_registration():
    """The fake app must collect what FastMCP would have registered."""
    app = garmin._Collector()

    @app.tool()
    async def some_tool(x: str) -> str:
        return x

    @app.tool(name="renamed")
    async def other(x: str) -> str:
        return x

    assert set(app.tools) == {"some_tool", "renamed"}, app.tools


def test_tools_harvested():
    """Needs tokens: proves every module registered against the real client."""
    registry = garmin.tools()
    assert len(registry) > 100, f"only {len(registry)} tools harvested"
    for expected in ("get_sleep_data", "get_activities", "create_run_workout",
                     "upsert_and_log", "schedule_week", "get_body_battery"):
        assert expected in registry, f"missing tool: {expected}"
    # __main__ must never be imported - it boots the MCP server on import
    import sys
    assert "garmin_mcp.__main__" not in sys.modules


def test_live_call():
    name = garmin.raw("get_full_name")
    assert name, "logged in but got an empty name back"
    return name


if __name__ == "__main__":
    offline = [test_arg_parsing, test_unwrap, test_collector_matches_mcp_registration]
    for check in offline:
        check()
        print(f"ok  {check.__name__}")

    test_tools_harvested()
    print(f"ok  test_tools_harvested ({len(garmin.tools())} tools)")
    print(f"ok  test_live_call (account: {test_live_call()})")
    print("\nall checks passed")
