#!/usr/bin/env python3
"""ccstatuskit custom module: Cursor included / auto / API usage.

Stale-while-revalidate: print the cache immediately, refresh in the
background if it is older than 5 minutes. Must finish well under
ccstatuskit's 250ms custom-module budget.

Percent fields from GetCurrentPeriodUsage:
- included: includedSpend / limit (dashboard "included usage")
- auto / api: autoPercentUsed / apiPercentUsed, already in percent
  (0.89 means 0.89%, dashboard rounds to 1%)
"""
from __future__ import annotations

import json
import os
import sqlite3
import subprocess
import sys
import urllib.error
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path

# ~/.config/ccstatuskit is a symlink into the dotfiles repo, so the cache
# lives under XDG_CACHE_HOME instead of next to this script.
CACHE = Path(
    os.environ.get(
        "CURSOR_USAGE_CACHE",
        Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache")
        / "ccstatuskit"
        / "cursor-usage.json",
    )
)
STATE_DB = Path.home() / "Library" / "Application Support" / "Cursor" / "User" / "globalStorage" / "state.vscdb"
USAGE_URL = "https://api2.cursor.sh/aiserver.v1.DashboardService/GetCurrentPeriodUsage"
TTL = timedelta(seconds=int(os.environ.get("CURSOR_USAGE_MAX_AGE", "300")))

GRAY = "\033[38;2;117;113;94m"
ORANGE = "\033[38;2;253;151;31m"
RED = "\033[38;2;249;38;114m"
RESET = "\033[0m"


def _parse_iso(value):
    if not isinstance(value, str) or not value:
        return None
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed


def _reset_at(value):
    if isinstance(value, (int, float)):
        return datetime.fromtimestamp(value / 1000.0, timezone.utc)
    if isinstance(value, str) and value.isdigit():
        return datetime.fromtimestamp(int(value) / 1000.0, timezone.utc)
    return _parse_iso(value)


def _reset_text(reset):
    now = datetime.now(timezone.utc)
    delta = reset - now
    if delta.total_seconds() <= 0:
        return None
    local = reset.astimezone()
    if delta < timedelta(hours=24):
        return local.strftime("%H:%M")
    if delta < timedelta(days=6):
        return local.strftime("%a %H:%M")
    return local.strftime("%b ") + str(local.day)


def _number(value):
    if isinstance(value, bool) or value is None:
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def _included_percent(plan):
    included = _number(plan.get("includedSpend"))
    limit = _number(plan.get("limit"))
    remaining = _number(plan.get("remaining"))
    if included is None and limit is not None and remaining is not None:
        included = limit - remaining
    if included is not None and limit:
        return max(0.0, included / limit * 100.0)
    return None


def _field_percent(plan, key):
    raw = _number(plan.get(key))
    if raw is None:
        return None
    return raw


def _on_demand_percent(spend):
    if not isinstance(spend, dict):
        return None
    for used_key, limit_key in (
        ("individualUsed", "individualLimit"),
        ("pooledUsed", "pooledLimit"),
        ("used", "limit"),
        ("totalSpend", "limit"),
    ):
        used = _number(spend.get(used_key))
        limit = _number(spend.get(limit_key))
        if used is not None and limit:
            return max(0.0, used / limit * 100.0)
    return None


def _window(label, percent, reset=None):
    rounded = int(round(percent))
    if rounded >= 95:
        mark, color = "\u26d4", RED
    elif rounded >= 80:
        mark, color = "\u26a0", ORANGE
    else:
        mark, color = "", GRAY
    text = "%s %s%%" % (label, rounded)
    if mark:
        text += mark
    if reset:
        text += " \u2192%s" % reset
    return color + text + RESET


def _read_cache():
    try:
        data = json.loads(CACHE.read_text())
    except (OSError, ValueError):
        return None
    return data if isinstance(data, dict) else None


def _stale(cache):
    retrieved = _parse_iso(cache.get("retrieved_at"))
    if retrieved is None:
        return True
    return datetime.now(timezone.utc) - retrieved >= TTL


def _access_token():
    if STATE_DB.is_file():
        try:
            connection = sqlite3.connect("file:%s?mode=ro" % STATE_DB, uri=True)
            try:
                row = connection.execute(
                    "SELECT value FROM ItemTable WHERE key = ? LIMIT 1",
                    ("cursorAuth/accessToken",),
                ).fetchone()
            finally:
                connection.close()
            if row and isinstance(row[0], str) and row[0]:
                return row[0]
        except sqlite3.Error:
            pass
    return None


def _normalize(payload):
    plan = payload.get("planUsage") or {}
    spend = payload.get("spendLimitUsage") or {}
    return {
        "retrieved_at": datetime.now(timezone.utc).isoformat(),
        "billing_cycle_end": payload.get("billingCycleEnd"),
        "included_percent": _included_percent(plan),
        "auto_percent": _field_percent(plan, "autoPercentUsed"),
        "api_percent": _field_percent(plan, "apiPercentUsed"),
        "on_demand_percent": _on_demand_percent(spend),
    }


def _fetch():
    token = _access_token()
    if not token:
        raise RuntimeError("no Cursor access token")
    request = urllib.request.Request(
        USAGE_URL,
        data=b"{}",
        method="POST",
        headers={
            "Authorization": "Bearer " + token,
            "Content-Type": "application/json",
            "Connect-Protocol-Version": "1",
            "User-Agent": "ccstatuskit-cursor-usage/1",
        },
    )
    with urllib.request.urlopen(request, timeout=15) as response:
        payload = json.loads(response.read())
    if not isinstance(payload, dict):
        raise RuntimeError("unexpected usage payload")
    return _normalize(payload)


def _write_cache(data):
    CACHE.parent.mkdir(parents=True, exist_ok=True)
    tmp = CACHE.with_name(".%s.%s.tmp" % (CACHE.name, os.getpid()))
    try:
        tmp.write_text(json.dumps(data, indent=2) + "\n")
        tmp.replace(CACHE)
    except Exception:
        try:
            tmp.unlink()
        except OSError:
            pass
        raise


def _spawn_refresh():
    try:
        subprocess.Popen(
            [sys.executable, str(Path(__file__).resolve()), "--refresh"],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
    except OSError:
        pass


def _render(cache):
    parts = []
    reset = None
    try:
        at = _reset_at(cache.get("billing_cycle_end"))
        if at is not None:
            reset = _reset_text(at)
    except (TypeError, ValueError, OSError):
        reset = None

    included = cache.get("included_percent")
    if isinstance(included, (int, float)):
        parts.append(_window("incl", included))

    auto = cache.get("auto_percent")
    if isinstance(auto, (int, float)):
        parts.append(_window("auto", auto))

    api = cache.get("api_percent")
    if isinstance(api, (int, float)):
        parts.append(_window("api", api))

    on_demand = cache.get("on_demand_percent")
    if isinstance(on_demand, (int, float)):
        parts.append(_window("od", on_demand))

    if not parts:
        return
    line = " \u00b7 ".join(parts)
    if reset:
        line += " " + GRAY + "\u2192%s" % reset + RESET
    sys.stdout.write(line)


def main():
    if "--refresh" in sys.argv:
        _write_cache(_fetch())
        return
    cache = _read_cache()
    if cache is None or _stale(cache):
        _spawn_refresh()
    if cache is None:
        return
    _render(cache)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        if "--refresh" in sys.argv:
            sys.exit(1)
        # statusline: fail-soft
        sys.exit(0)
