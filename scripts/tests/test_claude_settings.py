""".claude/settings.json が登録する hook の仕様。

Usage:
    python3 -m unittest scripts/tests/test_claude_settings.py
"""

from __future__ import annotations

import json
import os
import re
import unittest
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[2]
SETTINGS = REPO_ROOT / ".claude" / "settings.json"

# hook のコマンドが指す、リポジトリから ~/.claude へ配置されるファイル
PLACED_PATH = re.compile(r"~/\.claude/((?:hooks|scripts|tools)/[A-Za-z0-9._/-]+)")


def hook_commands(settings: dict[str, Any]) -> dict[str, list[str]]:
    """イベント名から、そのイベントで走るコマンドの一覧への対応。"""
    return {
        event: [
            hook["command"]
            for group in groups
            for hook in group.get("hooks", [])
            if hook.get("type") == "command"
        ]
        for event, groups in settings.get("hooks", {}).items()
    }


class TestHooks(unittest.TestCase):
    def setUp(self) -> None:
        self.commands = hook_commands(json.loads(SETTINGS.read_text(encoding="utf-8")))

    def test_every_script_a_hook_points_at_exists_in_the_repo(self) -> None:
        for event, commands in self.commands.items():
            for command in commands:
                for relative in PLACED_PATH.findall(command):
                    with self.subTest(event=event, path=relative):
                        self.assertTrue((REPO_ROOT / ".claude" / relative).is_file())

    def test_usage_warning_runs_on_every_prompt(self) -> None:
        # apm の hook 配布に任せると、apm が settings.json へ書き足した項目を
        # settings.json の合成が消す（配列は丸ごと置き換える）。直接登録する。
        script = REPO_ROOT / ".claude" / "hooks" / "usage-warn.sh"

        self.assertIn(
            "bash ~/.claude/hooks/usage-warn.sh", self.commands["UserPromptSubmit"]
        )
        self.assertTrue(os.access(script, os.X_OK))

    def test_no_hook_is_left_for_apm_to_merge_into_settings(self) -> None:
        self.assertFalse((REPO_ROOT / ".apm" / "hooks").exists())
        self.assertFalse((REPO_ROOT / ".apm" / "scripts").exists())


if __name__ == "__main__":
    unittest.main()
