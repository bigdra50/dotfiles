"""Duplicate key detection for keybinding records."""

from __future__ import annotations

from collections import Counter


def detect_duplicate_keys(
    records: list[dict[str, str]],
) -> list[tuple[str, str, str, str]]:
    identity_counts: Counter[tuple[str, str, str, str]] = Counter()

    for record in records:
        identity = (
            record["tool"],
            record["context"],
            record["mode"],
            record["key"],
        )
        identity_counts[identity] += 1

    duplicates: list[tuple[str, str, str, str]] = []
    for identity, count in sorted(identity_counts.items()):
        if count > 1:
            duplicates.append(identity)

    return duplicates
