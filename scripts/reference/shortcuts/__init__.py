"""Shortcut extraction pipeline — functional core."""

from shortcuts.abbr_parser import parse_abbr_text
from shortcuts.alias_parser import parse_alias_text
from shortcuts.function_parser import parse_function_text
from shortcuts.schema import Shortcut, to_record, validate_record

__all__ = [
    "Shortcut",
    "parse_abbr_text",
    "parse_alias_text",
    "parse_function_text",
    "to_record",
    "validate_record",
]
