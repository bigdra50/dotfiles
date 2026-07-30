#!/usr/bin/env python3
"""Extract mise tasks as JSON."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

from tasks.transform import parse_tasks_json


def main() -> int:
    parser = argparse.ArgumentParser(description="Extract mise tasks")
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument("--input-file", type=Path, default=None)
    args = parser.parse_args()

    root = args.root.resolve()

    if args.input_file is not None:
        text = args.input_file.read_text(encoding="utf-8")
    else:
        result = subprocess.run(
            ["mise", "tasks", "--json"],
            cwd=root,
            check=True,
            capture_output=True,
            text=True,
        )
        text = result.stdout

    records = parse_tasks_json(text, root)
    json.dump(records, sys.stdout, indent=2, ensure_ascii=False)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
