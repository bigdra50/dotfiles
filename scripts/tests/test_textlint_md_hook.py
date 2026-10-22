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

# hook が差し戻す規則と、CI や mise run md:lint にだけ残す規則の例文。
# どれも、ほかの規則には当たらない 1 文にしてある。
BLOCKED_BY_HOOK = {
    "prh-writing-style": "これは設定ミスに他ならない。\n",
    "sembr": "一文目です。二文目です。\n",
    "no-strong-emphasis": FLAGGED,
}
PASSED_BY_HOOK = {
    "no-ai-words": "この部品を照合する。\n",
    "no-doubled-joshi": "私は東京は好きだ。\n",
    "prh-business": "設定を適切に変える。\n",
}
SESSION_ID = "test-session"


@unittest.skipUnless(TEXTLINT.exists(), "textlint が未導入（npm ci --prefix .claude）")
class HookScopeTest(unittest.TestCase):
    def setUp(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name)

    def run_hook(self, relpath: str, text: str = FLAGGED) -> str:
        """relpath に text を書いた md を置いて hook を 1 回呼び、stdout を返す。"""
        target = self.root / relpath
        target.parent.mkdir(parents=True)
        target.write_text(text, encoding="utf-8")
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

    def test_blocks_rules_kept_for_write_time(self) -> None:
        for rule, text in BLOCKED_BY_HOOK.items():
            with self.subTest(rule=rule):
                out = self.run_hook(f"{rule}/docs/guide.md", text)
                self.assertEqual(json.loads(out)["decision"], "block")

    def test_passes_rules_left_to_ci_and_yomiyasu(self) -> None:
        for rule, text in PASSED_BY_HOOK.items():
            with self.subTest(rule=rule):
                out = self.run_hook(f"{rule}/docs/guide.md", text)
                self.assertEqual(out, "")


@unittest.skipUnless(TEXTLINT.exists(), "textlint が未導入（npm ci --prefix .claude）")
class FullLintTest(unittest.TestCase):
    """hook で外した規則も、CI と mise run md:lint では今までどおり指摘する。"""

    def test_reports_rules_passed_by_hook(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            for rule, text in PASSED_BY_HOOK.items():
                with self.subTest(rule=rule):
                    target = Path(tmp) / f"{rule}.md"
                    target.write_text(text, encoding="utf-8")
                    proc = subprocess.run(
                        [
                            "bash",
                            str(REPO_ROOT / "scripts" / "md-lint.sh"),
                            str(target),
                        ],
                        check=False,
                        capture_output=True,
                        text=True,
                        env={
                            k: v for k, v in os.environ.items() if k != "MD_LINT_CONFIG"
                        },
                    )
                    self.assertIn(target.name, proc.stdout)

    def test_kiku_is_reported_by_prh_only(self) -> None:
        # 「効く」は prh-business が言い換え先付きで指摘する。no-ai-words は活用形の
        # 表層（効か、効い）で照合するので、allows は活用形まで外す必要がある。
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "kiku.md"
            target.write_text(
                "設定が効く。\n設定が効かない。\n設定が効いた。\n", encoding="utf-8"
            )
            proc = subprocess.run(
                [
                    str(TEXTLINT),
                    "-c",
                    str(REPO_ROOT / ".claude" / ".textlintrc.json"),
                    "-f",
                    "compact",
                    str(target),
                ],
                check=False,
                capture_output=True,
                text=True,
            )
            self.assertIn("textlint-rule-prh", proc.stdout)
            self.assertNotIn("no-ai-words", proc.stdout)


if __name__ == "__main__":
    unittest.main()
