"""Keybinding extraction pipeline — functional core."""

from keybindings.dedup import detect_duplicate_keys
from keybindings.schema import Keybinding, to_record, validate_record

__all__ = [
    "Keybinding",
    "detect_duplicate_keys",
    "to_record",
    "validate_record",
]
