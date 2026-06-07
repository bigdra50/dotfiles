#!/usr/bin/env python3
"""Render the reference hub landing page (site root index.html)."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from datetime import UTC, datetime
from pathlib import Path

from common.hub_html import render_hub
from common.nav import DOMAIN_ORDER

NOTES = {
    "keybindings": "wezterm · zsh · skhd · nvim",
    "shortcuts": "aliases · abbreviations · functions",
    "tasks": "mise task catalog",
    "claude": "skills · agents · commands · rules",
}


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


def build_cards(counts: dict[str, int]) -> list[dict[str, str]]:
    cards: list[dict[str, str]] = []
    for slug, label in DOMAIN_ORDER:
        cards.append(
            {
                "slug": slug,
                "label": label,
                "count": str(counts.get(slug, 0)),
                "note": NOTES.get(slug, ""),
            }
        )
    return cards


def main() -> int:
    parser = argparse.ArgumentParser(description="Render the reference hub page")
    parser.add_argument(
        "--counts",
        required=True,
        help='JSON object of per-domain record counts, e.g. {"keybindings": 384}',
    )
    parser.add_argument("--out")
    args = parser.parse_args()

    counts = json.loads(args.counts)
    if not isinstance(counts, dict):
        raise ValueError("--counts must be a JSON object")

    meta = {
        "generated_at": datetime.now(UTC).isoformat(),
        "commit": resolve_git_commit(),
    }
    content = render_hub(build_cards(counts), meta)

    if args.out is None:
        sys.stdout.write(content)
        return 0
    out_path = Path(args.out)
    if out_path.is_dir() or args.out.endswith("/"):
        out_path = out_path / "index.html"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(content, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
