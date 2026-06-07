"""Pure parsers and diff logic for WezTerm show-keys --lua output."""

from __future__ import annotations

import re
from dataclasses import dataclass

from keybindings.schema import Keybinding

BINDING_LINE_PATTERN = re.compile(
    r"^\s*\{\s*key\s*=\s*'((?:\\.|[^'])*)'\s*,\s*mods\s*=\s*'([^']*)'\s*,"
    r"\s*action\s*=\s*(.+?)\s*\},\s*$"
)
KEYS_SECTION_PATTERN = re.compile(r"^\s*keys\s*=\s*\{")
KEY_TABLES_SECTION_PATTERN = re.compile(r"^\s*key_tables\s*=\s*\{")
KEY_TABLE_NAME_PATTERN = re.compile(r"^\s*(\w+)\s*=\s*\{")
EMIT_EVENT_PATTERN = re.compile(r"^EmitEvent\s+'user-defined-\d+'$")


@dataclass(frozen=True)
class ParsedWeztermKey:
    context: str
    key: str
    mods: str
    action: str


def unescape_lua_key(key: str) -> str:
    return key.replace("\\'", "'").replace('\\"', '"')


def normalize_mods(mods: str) -> str:
    if mods == "NONE":
        return "NONE"
    parts = sorted(mods.split("|"))
    return "|".join(parts)


def strip_act_prefix(action: str) -> str:
    if action.startswith("act."):
        return action[4:]
    return action


def describe_emit_event_action(action: str) -> str:
    if EMIT_EVENT_PATTERN.match(action):
        return "user callback (defined in config)"
    return ""


def parse_show_keys_lua(text: str) -> list[ParsedWeztermKey]:
    parsed: list[ParsedWeztermKey] = []
    in_keys = False
    in_key_tables = False
    current_context = ""

    for line_number, line in enumerate(text.splitlines(), start=1):
        stripped = line.strip()

        if KEYS_SECTION_PATTERN.match(line):
            in_keys = True
            in_key_tables = False
            current_context = "keys"
            continue

        if KEY_TABLES_SECTION_PATTERN.match(line):
            in_keys = False
            in_key_tables = True
            continue

        if in_key_tables:
            table_match = KEY_TABLE_NAME_PATTERN.match(line)
            if table_match is not None:
                current_context = table_match.group(1)
                continue

        if in_keys and stripped == "},":
            in_keys = False
            continue

        if "{ key =" not in line:
            continue

        binding_match = BINDING_LINE_PATTERN.match(line)
        if binding_match is None:
            raise ValueError(
                f"invalid WezTerm binding syntax at line {line_number}: {line!r}"
            )

        key_raw, mods_raw, action_raw = binding_match.groups()
        action = strip_act_prefix(action_raw.strip())

        parsed.append(
            ParsedWeztermKey(
                context=current_context,
                key=unescape_lua_key(key_raw),
                mods=normalize_mods(mods_raw),
                action=action,
            )
        )

    return parsed


def _identity(entry: ParsedWeztermKey) -> tuple[str, str, str]:
    return (entry.context, entry.key, entry.mods)


def _index_bindings(
    bindings: list[ParsedWeztermKey],
) -> dict[tuple[str, str, str], ParsedWeztermKey]:
    indexed: dict[tuple[str, str, str], ParsedWeztermKey] = {}
    for entry in bindings:
        indexed[_identity(entry)] = entry
    return indexed


def diff_against_default(
    effective: list[ParsedWeztermKey],
    default: list[ParsedWeztermKey],
) -> list[Keybinding]:
    default_index = _index_bindings(default)
    results: list[Keybinding] = []

    for entry in effective:
        identity = _identity(entry)
        default_entry = default_index.get(identity)

        if default_entry is None:
            origin = "custom"
            change = "added"
            source = ".wezterm.lua"
        elif default_entry.action == entry.action:
            origin = "default"
            change = "unchanged"
            source = "wezterm builtin"
        else:
            origin = "custom"
            change = "overridden"
            source = ".wezterm.lua"

        results.append(
            Keybinding(
                tool="wezterm",
                context=entry.context,
                mode=entry.mods,
                key=entry.key,
                action=entry.action,
                description=describe_emit_event_action(entry.action),
                source=source,
                origin=origin,
                change=change,
            )
        )

    return results
