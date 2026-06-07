"""Tests for WezTerm Lua parsing and diffing."""

from __future__ import annotations

import unittest
from pathlib import Path

from keybindings.wezterm_lua import (
    ParsedWeztermKey,
    diff_against_default,
    normalize_mods,
    parse_show_keys_lua,
    unescape_lua_key,
)

FIXTURES = Path(__file__).parent / "fixtures"


class TestWeztermLua(unittest.TestCase):
    def setUp(self) -> None:
        self.effective_text = (FIXTURES / "wezterm-effective.lua").read_text(
            encoding="utf-8"
        )
        self.default_text = (FIXTURES / "wezterm-default.lua").read_text(
            encoding="utf-8"
        )

    def test_parse_show_keys_lua_counts_effective_fixture(self) -> None:
        parsed = parse_show_keys_lua(self.effective_text)
        self.assertEqual(len(parsed), 243)

    def test_parse_show_keys_lua_counts_default_fixture(self) -> None:
        parsed = parse_show_keys_lua(self.default_text)
        self.assertEqual(len(parsed), 214)

    def test_normalize_mods_sorts_pipe_separated_modifiers(self) -> None:
        self.assertEqual(normalize_mods("SHIFT|CTRL"), "CTRL|SHIFT")
        self.assertEqual(normalize_mods("NONE"), "NONE")

    def test_unescape_lua_key(self) -> None:
        self.assertEqual(unescape_lua_key(r"\'"), "'")
        self.assertEqual(unescape_lua_key(r"\""), '"')

    def test_parse_show_keys_lua_raises_on_malformed_binding(self) -> None:
        malformed = "    { key = 'Tab', mods = BROKEN },\n"
        with self.assertRaises(ValueError):
            parse_show_keys_lua(malformed)

    def test_diff_against_default_emits_all_change_kinds(self) -> None:
        effective = parse_show_keys_lua(self.effective_text)
        default = parse_show_keys_lua(self.default_text)
        diff = diff_against_default(effective, default)

        changes = {entry.change for entry in diff}
        self.assertIn("added", changes)
        self.assertIn("unchanged", changes)

        synthetic_diff = diff_against_default(
            [ParsedWeztermKey("keys", "Z", "CTRL", "CustomAction")],
            [ParsedWeztermKey("keys", "Z", "CTRL", "DefaultAction")],
        )
        self.assertEqual(synthetic_diff[0].change, "overridden")

    def test_diff_leader_bindings_are_added(self) -> None:
        effective = parse_show_keys_lua(self.effective_text)
        default = parse_show_keys_lua(self.default_text)
        diff = diff_against_default(effective, default)

        leader_added = [
            entry
            for entry in diff
            if entry.change == "added" and "LEADER" in entry.mode
        ]
        self.assertGreater(len(leader_added), 0)

    def test_diff_emit_event_description(self) -> None:
        effective = parse_show_keys_lua(self.effective_text)
        default = parse_show_keys_lua(self.default_text)
        diff = diff_against_default(effective, default)

        emit_events = [
            entry
            for entry in diff
            if entry.action.startswith("EmitEvent 'user-defined-")
        ]
        self.assertGreater(len(emit_events), 0)
        self.assertEqual(
            emit_events[0].description,
            "user callback (defined in config)",
        )


if __name__ == "__main__":
    unittest.main()
