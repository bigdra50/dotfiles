#!/usr/bin/env python3
"""Extract WezTerm keybindings as JSON."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

from keybindings.schema import to_record
from keybindings.wezterm_lua import diff_against_default, parse_show_keys_lua


def read_lua_from_wezterm(*, use_default_config: bool, config_file: str | None) -> str:
    command = ["wezterm"]
    if use_default_config:
        command.append("-n")
    elif config_file is not None:
        command.extend(["--config-file", config_file])
    command.extend(["show-keys", "--lua"])

    completed = subprocess.run(
        command,
        check=True,
        capture_output=True,
        text=True,
    )
    return completed.stdout


def main() -> int:
    parser = argparse.ArgumentParser(description="Extract WezTerm keybindings")
    parser.add_argument("--effective-file", type=Path)
    parser.add_argument("--default-file", type=Path)
    parser.add_argument("--config-file", type=str)
    args = parser.parse_args()

    if args.effective_file is not None:
        effective_text = args.effective_file.read_text(encoding="utf-8")
    else:
        effective_text = read_lua_from_wezterm(
            use_default_config=False,
            config_file=args.config_file,
        )

    if args.default_file is not None:
        default_text = args.default_file.read_text(encoding="utf-8")
    else:
        default_text = read_lua_from_wezterm(use_default_config=True, config_file=None)

    effective = parse_show_keys_lua(effective_text)
    default = parse_show_keys_lua(default_text)
    records = [to_record(kb) for kb in diff_against_default(effective, default)]

    json.dump(records, sys.stdout, indent=2, ensure_ascii=False)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
