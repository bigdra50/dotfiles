"""Tests for Neovim keymap diffing."""

from __future__ import annotations

import unittest
from pathlib import Path

from keybindings.nvim_diff import (
    NvimKeymap,
    exclude_builtin,
    normalize_lhs,
    parse_keymap_json,
)

FIXTURES = Path(__file__).parent / "fixtures"


class TestNvimDiff(unittest.TestCase):
    def setUp(self) -> None:
        self.config_text = (FIXTURES / "nvim-config.json").read_text(encoding="utf-8")
        self.clean_text = (FIXTURES / "nvim-clean.json").read_text(encoding="utf-8")

    def test_parse_keymap_json_counts_config_fixture(self) -> None:
        parsed = parse_keymap_json(self.config_text)
        self.assertEqual(len(parsed), 239)

    def test_parse_keymap_json_counts_clean_fixture(self) -> None:
        parsed = parse_keymap_json(self.clean_text)
        self.assertEqual(len(parsed), 111)

    def test_normalize_lhs_maps_leader_space(self) -> None:
        self.assertEqual(normalize_lhs(" fmt"), "<leader>fmt")

    def test_exclude_builtin_emits_added_and_overridden(self) -> None:
        config_maps = parse_keymap_json(self.config_text)
        clean_maps = parse_keymap_json(self.clean_text)
        diff = exclude_builtin(config_maps, clean_maps)

        changes = {entry.change for entry in diff}
        self.assertIn("added", changes)

        synthetic_diff = exclude_builtin(
            [NvimKeymap("n", "q", ":q<CR>", "", False)],
            [NvimKeymap("n", "q", ":quit<CR>", "", False)],
        )
        self.assertEqual(synthetic_diff[0].change, "overridden")

    def test_exclude_builtin_custom_count_meets_minimum(self) -> None:
        config_maps = parse_keymap_json(self.config_text)
        clean_maps = parse_keymap_json(self.clean_text)
        diff = exclude_builtin(config_maps, clean_maps)
        self.assertGreaterEqual(len(diff), 50)

    def test_exclude_builtin_uses_callback_action(self) -> None:
        config_maps = parse_keymap_json(self.config_text)
        clean_maps = parse_keymap_json(self.clean_text)
        diff = exclude_builtin(config_maps, clean_maps)

        callback_entries = [entry for entry in diff if entry.action == "(lua callback)"]
        self.assertGreater(len(callback_entries), 0)

    def test_exclude_builtin_omits_plug_mappings(self) -> None:
        diff = exclude_builtin(
            [
                NvimKeymap("n", "<Plug>(MyPluginAction)", "", "", False),
                NvimKeymap("n", "q", ":q<CR>", "", False),
            ],
            [],
        )
        keys = [entry.key for entry in diff]
        self.assertNotIn("<Plug>(MyPluginAction)", keys)
        self.assertIn("q", keys)

    def test_exclude_builtin_no_op_fallback(self) -> None:
        diff = exclude_builtin(
            [NvimKeymap("n", "x", "", "", False)],
            [],
        )
        self.assertEqual(len(diff), 1)
        self.assertEqual(diff[0].action, "(no-op)")


if __name__ == "__main__":
    unittest.main()
