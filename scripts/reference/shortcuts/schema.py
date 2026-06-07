"""Schema definitions and validation for shortcut records."""

from __future__ import annotations

from dataclasses import dataclass

ALLOWED_KINDS: frozenset[str] = frozenset({"alias", "abbr", "function"})

REQUIRED_NON_EMPTY_FIELDS: tuple[str, ...] = ("kind", "name", "source")


@dataclass(frozen=True)
class Shortcut:
    kind: str
    name: str
    value: str
    description: str
    source: str


def to_record(shortcut: Shortcut) -> dict[str, str]:
    return {
        "kind": shortcut.kind,
        "name": shortcut.name,
        "value": shortcut.value,
        "description": shortcut.description,
        "source": shortcut.source,
    }


def validate_record(record: dict[str, str]) -> list[str]:
    errors: list[str] = []

    for field in REQUIRED_NON_EMPTY_FIELDS:
        value = record.get(field, "")
        if not isinstance(value, str) or not value.strip():
            errors.append(f"missing or empty required field: {field}")

    kind = record.get("kind", "")
    if kind and kind not in ALLOWED_KINDS:
        errors.append(f"invalid kind: {kind!r}")

    for optional_field in ("value", "description"):
        field_value = record.get(optional_field)
        if field_value is not None and not isinstance(field_value, str):
            errors.append(f"{optional_field} must be a string")

    return errors
