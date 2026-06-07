#!/usr/bin/env python3
"""Validate keybinding JSON records."""

from __future__ import annotations

import argparse
import json
import sys
from collections import Counter

from keybindings.dedup import detect_duplicate_keys
from keybindings.schema import validate_record

MINIMUM_CUSTOM_COUNTS: dict[str, int] = {
    "wezterm": 25,
    "zsh": 11,
    "skhd": 30,
    "nvim": 50,
}


def load_records(input_path: str | None) -> list[dict[str, str]]:
    if input_path is None or input_path == "-":
        text = sys.stdin.read()
    else:
        with open(input_path, encoding="utf-8") as handle:
            text = handle.read()
    loaded = json.loads(text)
    if not isinstance(loaded, list):
        raise ValueError("input JSON must be an array")
    return loaded


def count_custom_by_tool(records: list[dict[str, str]]) -> Counter[str]:
    counts: Counter[str] = Counter()
    for record in records:
        if record.get("origin") == "custom":
            counts[record["tool"]] += 1
    return counts


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate keybinding records")
    parser.add_argument("--input", default="-")
    parser.add_argument("--count-only", action="store_true")
    args = parser.parse_args()

    records = load_records(None if args.input == "-" else args.input)

    if args.count_only:
        sys.stdout.write(f"{len(records)}\n")
        return 0

    errors: list[str] = []

    for index, record in enumerate(records):
        field_errors = validate_record(record)
        for field_error in field_errors:
            errors.append(f"record[{index}]: {field_error}")

    duplicates = detect_duplicate_keys(records)
    for tool, context, mode, key in duplicates:
        errors.append(
            "duplicate key identity: "
            f"tool={tool!r} context={context!r} mode={mode!r} key={key!r}"
        )

    custom_counts = count_custom_by_tool(records)
    for tool, minimum in MINIMUM_CUSTOM_COUNTS.items():
        actual = custom_counts.get(tool, 0)
        if actual < minimum:
            errors.append(
                f"minimum custom count not met for {tool}: "
                f"expected>={minimum}, actual={actual}"
            )

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
