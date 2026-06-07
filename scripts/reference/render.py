#!/usr/bin/env python3
"""Render reference records to HTML or TSV for a given domain.

Each domain (keybindings, shortcuts, tasks, claude) exposes a `page` module
with PAGE_CONFIG, TSV_FIELDS, and build_meta(records). This script dispatches
on --domain so the renderer itself stays domain-agnostic.
"""

from __future__ import annotations

import argparse
import importlib
import json
import subprocess
import sys
from datetime import UTC, datetime
from pathlib import Path

from common.render_html import render_searchable_html
from common.render_tsv import render_tsv


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


def resolve_git_commit() -> str:
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            check=True,
            capture_output=True,
            text=True,
        )
        return result.stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return "unknown"


def resolve_output_path(out_arg: str | None, html_mode: bool) -> Path | None:
    if out_arg is None:
        return None
    out_path = Path(out_arg)
    if html_mode and (out_path.is_dir() or out_arg.endswith("/")):
        return out_path / "index.html"
    return out_path


def write_output(content: str, out_path: Path | None) -> None:
    if out_path is None:
        sys.stdout.write(content)
        return
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(content, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Render reference records")
    parser.add_argument("--domain", default="keybindings")
    parser.add_argument("--input", default="-")
    parser.add_argument("--html", action="store_true")
    parser.add_argument("--tsv", action="store_true")
    parser.add_argument("--out")
    args = parser.parse_args()

    if args.html == args.tsv:
        print("exactly one of --html or --tsv is required", file=sys.stderr)
        return 1

    page = importlib.import_module(f"{args.domain}.page")
    input_path = None if args.input == "-" else args.input
    records = load_records(input_path)

    if args.html:
        meta = dict(page.build_meta(records))
        meta["generated_at"] = datetime.now(UTC).isoformat()
        meta["commit"] = resolve_git_commit()
        content = render_searchable_html(records, page.PAGE_CONFIG, meta)
        out_path = resolve_output_path(args.out, html_mode=True)
    else:
        content = render_tsv(records, page.TSV_FIELDS)
        out_path = resolve_output_path(args.out, html_mode=False)

    write_output(content, out_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
