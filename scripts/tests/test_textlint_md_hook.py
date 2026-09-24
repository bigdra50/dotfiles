""".claude/hooks/textlint-md.sh（Write|Edit の PostToolUse hook）が差し戻す範囲の仕様。

Usage:
    python3 -m unittest discover -s scripts/tests
"""

from __future__ import annotations

import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
HOOK = REPO_ROOT / ".claude" / "hooks" / "textlint-md.sh"
TEXTLINT = REPO_ROOT / ".claude" / "node_modules" / ".bin" / "textlint"

# no-strong-emphasis が必ず指摘する文。hook が検査したかどうかの目印にする
FLAGGED = "これは **強調** を含む文です。\n"
SESSION_ID = "test-session"


@unittest.skipUnless(TEXTLINT.exists(), "textlint が未導入（npm ci --prefix .claude）")
class HookScopeTest(unittest.TestCase):
    def setUp(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name)

    def run_hook(self, relpath: str) -> str:
        """relpath に指摘の出る md を置いて hook を 1 回呼び、stdout を返す。"""
        target = self.root / relpath
        target.parent.mkdir(parents=True)
        target.write_text(FLAGGED, encoding="utf-8")
        payload = {
            "session_id": SESSION_ID,
            "cwd": str(self.root),
            "tool_input": {"file_path": str(target)},
        }
        env = {**os.environ, "TMPDIR": str(self.root / "hook-tmp")}
        env.pop("CLAUDE_TEXTLINT_DISABLE", None)
        proc = subprocess.run(
            ["bash", str(HOOK)],
            input=json.dumps(payload),
            capture_output=True,
            text=True,
            env=env,
            check=True,
        )
        return proc.stdout

    def test_blocks_markdown_in_a_project(self) -> None:
        out = self.run_hook("repo/docs/guide.md")
        self.assertEqual(json.loads(out)["decision"], "block")

    def test_skips_claude_memory(self) -> None:
        out = self.run_hook(".claude/projects/-Users-me/memory/note.md")
        self.assertEqual(out, "")

    def test_skips_session_scratchpad(self) -> None:
        out = self.run_hook("claude-501/-Users-me/0f1e2d3c/scratchpad/draft.md")
        self.assertEqual(out, "")


if __name__ == "__main__":
    unittest.main()
