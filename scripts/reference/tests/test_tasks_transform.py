"""Tests for mise task transforms."""

from __future__ import annotations

import unittest
from pathlib import Path

from tasks.transform import (
    RECORD_KEYS,
    classify_category,
    join_list,
    normalize_source,
    parse_tasks_json,
)

FIXTURES = Path(__file__).parent / "fixtures"


class TestTasksTransform(unittest.TestCase):
    def setUp(self) -> None:
        self.fixture_text = (FIXTURES / "mise-tasks.json").read_text(encoding="utf-8")
        self.repo_root = Path("/repo")
        self.records = parse_tasks_json(self.fixture_text, self.repo_root)
        self.by_name = {record["name"]: record for record in self.records}

    def test_colon_prefix_maps_to_category(self) -> None:
        self.assertEqual(classify_category("keys:build"), "keys")
        self.assertEqual(self.by_name["keys:build"]["category"], "keys")
        self.assertEqual(self.by_name["sh:fmt:fix"]["category"], "sh")

    def test_no_colon_maps_to_general(self) -> None:
        self.assertEqual(classify_category("setup"), "general")
        self.assertEqual(self.by_name["setup"]["category"], "general")
        self.assertEqual(self.by_name["disk-usage"]["category"], "general")

    def test_in_repo_source_becomes_relative_posix_path(self) -> None:
        self.assertEqual(
            normalize_source("/repo/mise.toml", self.repo_root),
            "mise.toml",
        )
        self.assertEqual(
            self.by_name["keys:build"]["source"],
            "mise.toml",
        )
        self.assertEqual(
            self.by_name["setup"]["source"],
            ".config/mise/tasks/setup",
        )

    def test_out_of_repo_source_becomes_global_basename(self) -> None:
        self.assertEqual(
            normalize_source(
                "/Users/someone/.config/mise/tasks/globaltask",
                self.repo_root,
            ),
            "global:globaltask",
        )
        self.assertEqual(self.by_name["globaltask"]["source"], "global:globaltask")

    def test_empty_description_preserved(self) -> None:
        self.assertEqual(self.by_name["disk-usage"]["description"], "")

    def test_aliases_joined_with_commas(self) -> None:
        self.assertEqual(join_list(["fmt-fix", "format"]), "fmt-fix,format")
        self.assertEqual(join_list([]), "")
        self.assertEqual(self.by_name["sh:fmt:fix"]["aliases"], "fmt-fix,format")

    def test_depends_joined_with_commas(self) -> None:
        self.assertEqual(join_list(["setup", "sh:lint"]), "setup,sh:lint")
        self.assertEqual(join_list([]), "")
        self.assertEqual(self.by_name["disk-usage"]["depends"], "setup")
        self.assertEqual(self.by_name["sh:fmt:fix"]["depends"], "setup,sh:lint")

    def test_record_has_exact_schema_keys(self) -> None:
        for record in self.records:
            self.assertEqual(set(record.keys()), set(RECORD_KEYS))

    def test_records_sorted_by_category_then_name(self) -> None:
        keys = [(record["category"], record["name"]) for record in self.records]
        self.assertEqual(keys, sorted(keys))


if __name__ == "__main__":
    unittest.main()
