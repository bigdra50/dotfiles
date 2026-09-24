"""setup が JSON の設定を live のファイルへ合成する処理の仕様。

対象:
- scripts/lib.sh の merge_json_onto（Claude の settings.json と Cursor の cli-config.json が使う）
- scripts/setup/symlinks.sh の link_config と apply_cursor_config

Usage:
    python3 -m unittest scripts/tests/test_setup_config_merge.py
"""

from __future__ import annotations

import json
import os
import shutil
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[2]
LIB = REPO_ROOT / "scripts" / "lib.sh"
SYMLINKS = REPO_ROOT / "scripts" / "setup" / "symlinks.sh"

ATTRIBUTION_OFF = {"attributeCommitsToAgent": False, "attributePRsToAgent": False}
ATTRIBUTION_ON = {"attributeCommitsToAgent": True, "attributePRsToAgent": True}


@unittest.skipUnless(shutil.which("jq"), "jq が無い")
class SetupTestCase(unittest.TestCase):
    def setUp(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name)
        self.home = self.root / "home"
        self.home.mkdir()
        self.dotfiles = self.root / "dotfiles"
        self.dotfiles.mkdir()

    def bash(self, script: str) -> subprocess.CompletedProcess[str]:
        env = {**os.environ, "HOME": str(self.home), "INTERACTIVE": "false"}
        return subprocess.run(
            ["bash", "-c", script],
            capture_output=True,
            text=True,
            env=env,
            check=False,
        )

    @staticmethod
    def write_json(path: Path, data: object) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(data), encoding="utf-8")

    @staticmethod
    def read_json(path: Path) -> Any:
        return json.loads(path.read_text(encoding="utf-8"))


class MergeJsonOntoTest(SetupTestCase):
    def setUp(self) -> None:
        super().setUp()
        self.source = self.dotfiles / "settings.json"
        self.target = self.home / "settings.json"

    def merge(self) -> subprocess.CompletedProcess[str]:
        return self.bash(
            f'source "{LIB}"; merge_json_onto "{self.source}" "{self.target}"'
        )

    def test_dotfiles_keys_win_and_runtime_keys_stay(self) -> None:
        self.write_json(self.source, {"model": "opus", "env": {"A": "1"}})
        self.write_json(
            self.target, {"model": "old", "env": {"B": "2"}, "auth": {"id": "x"}}
        )

        proc = self.merge()

        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertEqual(
            self.read_json(self.target),
            {"model": "opus", "env": {"B": "2", "A": "1"}, "auth": {"id": "x"}},
        )

    def test_creates_a_missing_target_readable_only_by_the_owner(self) -> None:
        self.target = self.home / "sub" / "settings.json"
        self.write_json(self.source, {"model": "opus"})

        proc = self.merge()

        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertEqual(self.read_json(self.target), {"model": "opus"})
        self.assertEqual(stat.S_IMODE(self.target.stat().st_mode), 0o600)

    def test_invalid_source_leaves_the_target_untouched(self) -> None:
        self.source.write_text("{broken", encoding="utf-8")
        self.write_json(self.target, {"model": "old"})

        proc = self.merge()

        self.assertNotEqual(proc.returncode, 0)
        self.assertEqual(self.read_json(self.target), {"model": "old"})

    def test_replaces_a_symlink_into_the_repo_with_a_real_file(self) -> None:
        self.write_json(self.source, {"model": "opus"})
        self.target.symlink_to(self.source)

        proc = self.merge()

        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertFalse(self.target.is_symlink())
        self.assertEqual(self.read_json(self.target), {"model": "opus"})


class CursorConfigTest(SetupTestCase):
    """~/.config/cursor はリンクせず、管理するキーだけを live の cli-config.json へ当てる。"""

    def setUp(self) -> None:
        super().setUp()
        self.repo_dir = self.dotfiles / ".config" / "cursor"
        self.repo_config = self.repo_dir / "cli-config.json"
        # 追跡中のファイルには、最初にリンクしたマシンの設定が丸ごと入っている
        self.write_json(
            self.repo_config,
            {
                "attribution": ATTRIBUTION_OFF,
                "statusLine": {
                    "type": "command",
                    "command": "/Users/other/bin/statusline",
                },
                "sandbox": {"mode": "disabled"},
            },
        )
        self.live_dir = self.home / ".config" / "cursor"
        self.live_config = self.live_dir / "cli-config.json"

    def run_setup(self, function: str) -> subprocess.CompletedProcess[str]:
        return self.bash(
            f'source "{SYMLINKS}"; DOTFILES_DIR="{self.dotfiles}"; {function}'
        )

    def test_link_config_leaves_cursor_unlinked(self) -> None:
        (self.dotfiles / ".config" / "other").mkdir()

        proc = self.run_setup("link_config")

        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertTrue((self.home / ".config" / "other").is_symlink())
        self.assertFalse(self.live_dir.is_symlink())
        self.assertFalse(self.live_dir.exists())

    def test_turns_attribution_off_and_keeps_per_machine_keys(self) -> None:
        live = {
            "authInfo": {"email": "me@example.com"},
            "attribution": ATTRIBUTION_ON,
            "statusLine": {
                "type": "command",
                "command": "~/.config/cursor/statusline.sh",
            },
            "sandbox": {"mode": "enabled"},
        }
        self.write_json(self.live_config, live)

        proc = self.run_setup("apply_cursor_config")

        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertEqual(
            self.read_json(self.live_config), {**live, "attribution": ATTRIBUTION_OFF}
        )

    def test_does_not_write_a_config_before_cursor_does(self) -> None:
        proc = self.run_setup("apply_cursor_config")

        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertFalse(self.live_config.exists())

    def test_turns_a_legacy_directory_link_into_a_real_directory(self) -> None:
        # 以前の構成では ~/.config/cursor がリポジトリの .config/cursor を指し、
        # Cursor の設定と実行時ファイル（会話履歴、認証）がリポジトリ側に書かれていた
        live_state = {
            **self.read_json(self.repo_config),
            "authInfo": {"email": "me@example.com"},
        }
        self.write_json(self.repo_config, live_state)
        (self.repo_dir / "chats").mkdir()
        (self.repo_dir / "chats" / "a.json").write_text("{}", encoding="utf-8")
        tracked_before = self.repo_config.read_bytes()
        self.live_dir.parent.mkdir(parents=True)
        self.live_dir.symlink_to(self.repo_dir)

        proc = self.run_setup("apply_cursor_config")

        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertFalse(self.live_dir.is_symlink())
        self.assertTrue((self.live_dir / "chats" / "a.json").is_file())
        self.assertEqual(self.read_json(self.live_config), live_state)
        self.assertEqual(self.repo_config.read_bytes(), tracked_before)


if __name__ == "__main__":
    unittest.main()
