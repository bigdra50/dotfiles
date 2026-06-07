"""Page configuration for the mise tasks reference."""

from __future__ import annotations

import json
from collections import Counter

from common.page_config import Column, Filter, PageConfig

PAGE_CONFIG = PageConfig(
    title="mise Tasks",
    columns=(
        Column("category", "Category", kind="badge"),
        Column("name", "Name"),
        Column("description", "Description", kind="wrap"),
        Column("depends", "Depends", kind="wrap"),
        Column("source", "Source", kind="wrap"),
    ),
    filters=(Filter("category", "Category"),),
    search_fields=("name", "description", "aliases", "source"),
    badge_classes={},
    note="mise task catalog for this repository",
)

TSV_FIELDS = ("category", "name", "description", "depends", "source")


def build_meta(records: list[dict[str, str]]) -> dict[str, str]:
    counts: Counter[str] = Counter()
    for record in records:
        counts[record.get("category", "")] += 1
    return {"counts": json.dumps(dict(counts))}
