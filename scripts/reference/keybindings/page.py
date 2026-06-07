"""Page configuration for the keybindings reference."""

from __future__ import annotations

import json
from collections import Counter

from common.page_config import Column, Filter, PageConfig

PAGE_CONFIG = PageConfig(
    title="Keybindings",
    columns=(
        Column("tool", "Tool"),
        Column("mode", "Mode"),
        Column("key", "Key"),
        Column("action", "Action"),
        Column("description", "Description", kind="wrap"),
        Column("source", "Source", kind="wrap"),
        Column("change", "Change", kind="badge"),
    ),
    filters=(
        Filter("tool", "Tool", values=("wezterm", "zsh", "skhd", "nvim")),
        Filter("mode", "Mode"),
        Filter("origin", "Origin", values=("custom", "default"), default=("custom",)),
    ),
    search_fields=("key", "action", "description", "source"),
    badge_classes={
        "added": "badge-green",
        "overridden": "badge-orange",
        "unchanged": "badge-gray",
    },
    note="nvim: global maps only (v1)",
)

TSV_FIELDS = (
    "tool",
    "mode",
    "key",
    "action",
    "description",
    "origin",
    "change",
    "source",
)


def build_meta(records: list[dict[str, str]]) -> dict[str, str]:
    counts: Counter[str] = Counter()
    for record in records:
        counts[record.get("tool", "")] += 1
    return {"counts": json.dumps(dict(counts))}
