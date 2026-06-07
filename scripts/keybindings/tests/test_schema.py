"""Tests for keybinding schema helpers."""

from __future__ import annotations

import unittest

from keybindings.schema import Keybinding, to_record, validate_record


class TestSchema(unittest.TestCase):
    def test_to_record_roundtrip_fields(self) -> None:
        binding = Keybinding(
            tool="zsh",
            context="zle",
            mode="viins",
            key="jj",
            action="vi-cmd-mode",
            description="",
            source=".config/zsh/interface.zsh",
            origin="custom",
            change="added",
        )
        record = to_record(binding)
        self.assertEqual(record["tool"], "zsh")
        self.assertEqual(record["key"], "jj")

    def test_validate_record_accepts_valid_record(self) -> None:
        record = to_record(
            Keybinding(
                tool="skhd",
                context="focus window",
                mode="alt",
                key="x",
                action="yabai -m window --focus recent",
                description="",
                source=".skhdrc",
                origin="custom",
                change="added",
            )
        )
        self.assertEqual(validate_record(record), [])

    def test_validate_record_reports_invalid_tool(self) -> None:
        record = {
            "tool": "emacs",
            "context": "global",
            "mode": "normal",
            "key": "C-x",
            "action": "save",
            "description": "",
            "source": "init.el",
            "origin": "custom",
            "change": "added",
        }
        errors = validate_record(record)
        self.assertTrue(any("invalid tool" in error for error in errors))

    def test_validate_record_reports_missing_required_field(self) -> None:
        record = {
            "tool": "nvim",
            "context": "global:all-loaded",
            "mode": "n",
            "key": "q",
            "action": ":q<CR>",
            "description": "",
            "source": ".config/nvim",
            "origin": "custom",
            "change": "",
        }
        errors = validate_record(record)
        self.assertTrue(any("change" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
