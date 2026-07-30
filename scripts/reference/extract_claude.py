#!/usr/bin/env python3
"""Extract Claude Code assets as JSON."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from claude.extract import collect_claude_assets


def main() -> int:
    parser = argparse.ArgumentParser(description="Extract Claude Code assets")
    parser.add_argument("--root", type=Path, required=True)
    args = parser.parse_args()

    records = collect_claude_assets(args.root.resolve())
    json.dump(records, sys.stdout, indent=2, ensure_ascii=False)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
