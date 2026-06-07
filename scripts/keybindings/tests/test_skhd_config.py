"""Tests for skhd configuration parsing."""

from __future__ import annotations

import unittest
from pathlib import Path

from keybindings.skhd_config import parse_skhdrc

FIXTURES = Path(__file__).parent / "fixtures"


class TestSkhdConfig(unittest.TestCase):
    def setUp(self) -> None:
        self.valid_text = "\n".join(
            [
                "# focus window",
                "alt - x : yabai -m window --focus recent",
                "# swap window",
                "shift + alt - x : yabai -m window --swap recent",
            ]
        )
        self.fixture_text = (FIXTURES / "skhdrc-excerpt.skhdrc").read_text(
            encoding="utf-8"
        )

    def test_parse_skhdrc_assigns_comment_context(self) -> None:
        bindings = parse_skhdrc(self.valid_text)
        self.assertEqual(bindings[0].context, "focus window")
        self.assertEqual(bindings[1].context, "swap window")

    def test_parse_skhdrc_normalizes_modifiers(self) -> None:
        bindings = parse_skhdrc(self.valid_text)
        self.assertEqual(bindings[1].mode, "shift+alt")
        self.assertEqual(bindings[1].key, "x")

    def test_parse_skhdrc_fixture_count(self) -> None:
        valid_lines = [
            line
            for line in self.fixture_text.splitlines()
            if line.strip() and not line.startswith("invalid")
        ]
        bindings = parse_skhdrc("\n".join(valid_lines))
        self.assertEqual(len(bindings), 7)

    def test_parse_skhdrc_raises_on_invalid_line(self) -> None:
        with self.assertRaises(ValueError):
            parse_skhdrc("not a binding")


if __name__ == "__main__":
    unittest.main()
