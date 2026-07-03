"""Tests for Claude asset extraction."""

from __future__ import annotations

import unittest
from pathlib import Path

from claude.extract import collect_from_claude_dir

FIXTURES = Path(__file__).parent / "fixtures"
CLAUDE_DIR = FIXTURES / "claude"
FIXTURE_ROOT = FIXTURES


class TestClaudeExtract(unittest.TestCase):
    def setUp(self) -> None:
        self.records = collect_from_claude_dir(CLAUDE_DIR, FIXTURE_ROOT)
        self.by_name = {record["name"]: record for record in self.records}

    def test_extracts_all_asset_types(self) -> None:
        types = {record["type"] for record in self.records}
        self.assertEqual(types, {"agent", "command", "rule"})

    def test_extracts_agent_metadata(self) -> None:
        agent = self.by_name["example-agent"]
        self.assertEqual(agent["type"], "agent")
        self.assertIn("example agent", agent["description"].lower())
        self.assertEqual(agent["model"], "opus")

    def test_extracts_command_with_frontmatter(self) -> None:
        command = self.by_name["example-command"]
        self.assertEqual(command["type"], "command")
        self.assertEqual(command["description"], "Run the example command workflow.")

    def test_rule_description_falls_back_to_first_heading(self) -> None:
        rule = self.by_name["example"]
        self.assertEqual(rule["type"], "rule")
        self.assertEqual(rule["description"], "Example Rule")

    def test_command_without_frontmatter_uses_stem_and_heading(self) -> None:
        command = self.by_name["plain"]
        self.assertEqual(command["type"], "command")
        self.assertEqual(command["description"], "Plain Command")


if __name__ == "__main__":
    unittest.main()
