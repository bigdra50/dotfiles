#!/usr/bin/env python3
"""Extract Neovim keybindings by diffing config vs clean dumps."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from keybindings.nvim_diff import exclude_builtin, parse_keymap_json
from keybindings.schema import to_record


def main() -> int:
    parser = argparse.ArgumentParser(description="Diff Neovim keymap JSON dumps")
    parser.add_argument("--config-json", required=True, type=Path)
    parser.add_argument("--clean-json", required=True, type=Path)
    args = parser.parse_args()

    config_maps = parse_keymap_json(args.config_json.read_text(encoding="utf-8"))
    clean_maps = parse_keymap_json(args.clean_json.read_text(encoding="utf-8"))
    records = [to_record(kb) for kb in exclude_builtin(config_maps, clean_maps)]

    json.dump(records, sys.stdout, indent=2, ensure_ascii=False)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
