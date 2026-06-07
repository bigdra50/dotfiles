"""Page configuration for the Claude assets reference."""

from __future__ import annotations

import json
from collections import Counter

from common.nav import build_nav
from common.page_config import Column, Filter, PageConfig

PAGE_CONFIG = PageConfig(
    title="Claude Assets",
    nav=build_nav("claude"),
    columns=(
        Column("type", "Type", kind="badge"),
        Column("name", "Name"),
        Column("description", "Description", kind="wrap"),
        Column("source", "Source", kind="wrap"),
    ),
    filters=(Filter("type", "Type", values=("skill", "agent", "command", "rule")),),
    search_fields=("name", "description", "source"),
    badge_classes={
        "skill": "badge-blue",
        "agent": "badge-purple",
        "command": "badge-green",
        "rule": "badge-orange",
    },
    note="Catalog of Claude Code skills, agents, commands, and rules in .claude/",
)

TSV_FIELDS = ("type", "name", "description", "source")


def build_meta(records: list[dict[str, str]]) -> dict[str, str]:
    counts: Counter[str] = Counter()
    for record in records:
        counts[record.get("type", "")] += 1
    return {"counts": json.dumps(dict(counts))}
