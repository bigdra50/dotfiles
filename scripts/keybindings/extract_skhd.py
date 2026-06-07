#!/usr/bin/env python3
"""Extract skhd keybindings as JSON."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from keybindings.schema import to_record
from keybindings.skhd_config import parse_skhdrc


def main() -> int:
    parser = argparse.ArgumentParser(description="Extract skhd keybindings")
    parser.add_argument("--root", type=Path, required=True)
    args = parser.parse_args()

    skhdrc_path = args.root.resolve() / ".skhdrc"
    text = skhdrc_path.read_text(encoding="utf-8")
    records = [to_record(binding) for binding in parse_skhdrc(text)]

    json.dump(records, sys.stdout, indent=2, ensure_ascii=False)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
