"""Pure transforms for mise task records."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

RECORD_KEYS = ("category", "name", "description", "aliases", "depends", "source")


def classify_category(name: str) -> str:
    """Return the category prefix before the first colon, or ``general``."""
    if ":" in name:
        return name.split(":", 1)[0]
    return "general"


def join_list(items: list[str]) -> str:
    """Join a list of strings with commas; empty list yields an empty string."""
    return ",".join(items)


def normalize_source(path_str: str, repo_root: Path) -> str:
    """Convert an absolute source path to a repo-relative or global form."""
    path = Path(path_str)
    resolved_root = repo_root.resolve()
    try:
        relative = path.resolve().relative_to(resolved_root)
        return relative.as_posix()
    except ValueError:
        return f"global:{path.name}"


def task_source_path(task: dict[str, Any]) -> str:
    """Return the source path, preferring ``source`` over ``file``."""
    source = task.get("source")
    if source:
        return str(source)
    file_path = task.get("file")
    if file_path:
        return str(file_path)
    return ""


def transform_task(task: dict[str, Any], repo_root: Path) -> dict[str, str]:
    """Map one mise task object to a flat record."""
    name = str(task.get("name", ""))
    description = str(task.get("description", ""))
    aliases_raw = task.get("aliases", [])
    depends_raw = task.get("depends", [])

    aliases_list = (
        [str(item) for item in aliases_raw] if isinstance(aliases_raw, list) else []
    )
    depends_list = (
        [str(item) for item in depends_raw] if isinstance(depends_raw, list) else []
    )

    source_path = task_source_path(task)
    source = normalize_source(source_path, repo_root) if source_path else ""

    return {
        "category": classify_category(name),
        "name": name,
        "description": description,
        "aliases": join_list(aliases_list),
        "depends": join_list(depends_list),
        "source": source,
    }


def parse_tasks_json(text: str, repo_root: Path) -> list[dict[str, str]]:
    """Parse a ``mise tasks --json`` array and return sorted flat records."""
    raw: list[dict[str, Any]] = json.loads(text)
    records = [transform_task(task, repo_root) for task in raw]
    records.sort(key=lambda record: (record["category"], record["name"]))
    return records
