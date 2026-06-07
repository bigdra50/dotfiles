"""Page configuration for the shortcuts reference."""

from __future__ import annotations

import json
from collections import Counter

from common.page_config import Column, Filter, PageConfig

PAGE_CONFIG = PageConfig(
    title="Shortcuts",
    columns=(
        Column("kind", "Kind", kind="badge"),
        Column("name", "Name"),
        Column("value", "Value", kind="wrap"),
        Column("description", "Description", kind="wrap"),
        Column("source", "Source", kind="wrap"),
    ),
    filters=(Filter("kind", "Kind", values=("alias", "abbr", "function")),),
    search_fields=("name", "value", "description", "source"),
    badge_classes={
        "alias": "badge-blue",
        "abbr": "badge-green",
        "function": "badge-purple",
    },
    note="Zsh aliases, abbreviations, and shell functions from dotfiles.",
)

TSV_FIELDS = ("kind", "name", "value", "description", "source")


def build_meta(records: list[dict[str, str]]) -> dict[str, str]:
    counts: Counter[str] = Counter()
    for record in records:
        counts[record.get("kind", "")] += 1
    return {"counts": json.dumps(dict(counts))}
