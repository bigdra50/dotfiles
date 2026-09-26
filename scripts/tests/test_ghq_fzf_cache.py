"""Ctrl+] の ghq-fzf が表示するリポジトリ一覧キャッシュの仕様。

対象: .config/zsh/plugins/fzf.zsh の _ghq_cache_rebuild と _ghq_list_cached

Usage:
    python3 -m unittest scripts/tests/test_ghq_fzf_cache.py
"""

from __future__ import annotations

import os
import shutil
import subprocess
import tempfile
import textwrap
import time
import unittest
from collections.abc import Callable
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
PLUGIN = REPO_ROOT / ".config" / "zsh" / "plugins" / "fzf.zsh"

# 対話シェルが completion.zsh で有効にしているオプション。
# mark_dirs はグロブで得たディレクトリ名の末尾に / を付ける。
# 関数がオプションを戻さないと、github.com/a//C のようなパスを出力してしまう
INTERACTIVE_OPTIONS = "setopt mark_dirs globdots extended_glob"


@unittest.skipUnless(shutil.which("zsh") and shutil.which("ghq"), "zsh か ghq が無い")
class GhqCacheTestCase(unittest.TestCase):
    def setUp(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        base = Path(tmp.name)
        self.base = base
        self.root = base / "root"
        self.root.mkdir()
        self.cache_dir = base / "cache"
        self.cache_dir.mkdir()
        self.cache = self.cache_dir / "ghq-list"
        self.bin = base / "bin"
        self.bin.mkdir()
        self.env = {
            **os.environ,
            "GHQ_ROOT": str(self.root),
            # UTF-8 ロケールの zsh は大文字と小文字を区別せずに並べる。ghq の出力はバイト順
            "LC_ALL": "en_US.UTF-8",
        }

    def zsh(self, script: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["zsh", "-f", "-c", f'source "{PLUGIN}"; {INTERACTIVE_OPTIONS}; {script}'],
            capture_output=True,
            text=True,
            env=self.env,
            check=False,
        )

    def clone(self, repo: str) -> None:
        (self.root / repo / ".git").mkdir(parents=True)

    def ghq_list(self) -> list[str]:
        proc = subprocess.run(
            ["ghq", "list"], capture_output=True, text=True, env=self.env, check=True
        )
        return proc.stdout.splitlines()

    def build_cache(self, age: float = 3600) -> None:
        """いまの root を全走査したキャッシュを age 秒前に作った状態にする。

        root 配下のディレクトリはさらに 1 時間前の時刻にそろえ、キャッシュより前からあったことにする。
        """
        repos = self.ghq_list()
        self.cache.write_text("".join(f"{r}\n" for r in repos), encoding="utf-8")
        built = time.time() - age
        os.utime(self.cache, (built, built))
        for directory, subdirs, _ in os.walk(self.root):
            for name in subdirs:
                os.utime(Path(directory) / name, (built - 3600, built - 3600))

    def list_cached(self) -> list[str]:
        proc = self.zsh(f'_ghq_list_cached "{self.root}" "{self.cache}"')
        self.assertEqual(proc.returncode, 0, proc.stderr)
        return proc.stdout.splitlines()

    def cache_lines(self) -> list[str]:
        return self.cache.read_text(encoding="utf-8").splitlines()

    def cache_dir_entries(self) -> list[str]:
        return sorted(p.name for p in self.cache_dir.iterdir())


class ListCachedTest(GhqCacheTestCase):
    """全走査の合間に起きた clone と削除を、owner ディレクトリの更新時刻から補正する。"""

    def test_returns_the_cache_when_nothing_changed(self) -> None:
        self.clone("github.com/a/r1")
        self.clone("example.org/g/sub/r2")
        self.build_cache()

        self.assertEqual(
            self.list_cached(), ["example.org/g/sub/r2", "github.com/a/r1"]
        )

    def test_adds_a_repo_cloned_into_a_known_owner(self) -> None:
        self.clone("github.com/a/b")
        self.build_cache()

        self.clone("github.com/a/C")

        # ghq と同じバイト順（大文字が小文字より前）
        self.assertEqual(self.list_cached(), ["github.com/a/C", "github.com/a/b"])

    def test_adds_a_repo_cloned_under_a_new_owner(self) -> None:
        self.clone("github.com/a/r1")
        self.build_cache()

        self.clone("github.com/new-owner/r")

        self.assertEqual(
            self.list_cached(), ["github.com/a/r1", "github.com/new-owner/r"]
        )

    def test_drops_a_repo_removed_after_the_cache_was_built(self) -> None:
        self.clone("github.com/a/r1")
        self.clone("github.com/a/r2")
        self.build_cache()

        shutil.rmtree(self.root / "github.com" / "a" / "r1")

        self.assertEqual(self.list_cached(), ["github.com/a/r2"])

    def test_ignores_a_new_directory_that_is_not_a_repo(self) -> None:
        self.clone("github.com/a/r1")
        self.build_cache()

        (self.root / "github.com" / "a" / "scratch").mkdir()

        self.assertEqual(self.list_cached(), ["github.com/a/r1"])

    def test_keeps_nested_repos_under_a_changed_owner(self) -> None:
        self.clone("github.com/a/r1")
        self.clone("github.com/a/wt/feature")
        self.build_cache()

        self.clone("github.com/a/r2")

        self.assertEqual(
            self.list_cached(),
            ["github.com/a/r1", "github.com/a/r2", "github.com/a/wt/feature"],
        )

    def test_matches_a_full_scan_after_clones_and_removals(self) -> None:
        for repo in ["github.com/a/b", "github.com/a/d", "gitlab.com/g/sub/r"]:
            self.clone(repo)
        self.build_cache()

        self.clone("github.com/a/C")
        self.clone("github.com/n/_x")
        shutil.rmtree(self.root / "github.com" / "a" / "d")

        self.assertEqual(self.list_cached(), self.ghq_list())

    def test_prints_nothing_for_an_empty_cache(self) -> None:
        self.build_cache()

        proc = self.zsh(f'_ghq_list_cached "{self.root}" "{self.cache}"')

        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertEqual(proc.stdout, "")

    def test_prints_nothing_without_a_cache(self) -> None:
        self.clone("github.com/a/r1")

        proc = self.zsh(f'_ghq_list_cached "{self.root}" "{self.cache}"')

        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertEqual(proc.stdout, "")


class CacheRebuildTest(GhqCacheTestCase):
    """全走査でキャッシュを作り直す。"""

    def rebuild(self) -> subprocess.CompletedProcess[str]:
        return self.zsh(f'_ghq_cache_rebuild "{self.cache}"')

    def stub_ghq(self, body: str) -> None:
        """PATH の先頭に置く ghq の代役。本物は $REAL_GHQ で呼べる。"""
        stub = self.bin / "ghq"
        stub.write_text("#!/bin/sh\n" + textwrap.dedent(body), encoding="utf-8")
        stub.chmod(0o755)
        self.env["REAL_GHQ"] = shutil.which("ghq") or "ghq"
        self.env["PATH"] = f"{self.bin}{os.pathsep}{self.env['PATH']}"

    def test_writes_the_full_scan(self) -> None:
        self.clone("github.com/a/r1")
        self.clone("example.org/g/sub/r2")

        proc = self.rebuild()

        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertEqual(
            self.cache_lines(), ["example.org/g/sub/r2", "github.com/a/r1"]
        )
        self.assertEqual(self.cache_dir_entries(), ["ghq-list"])

    def test_lists_a_repo_cloned_while_the_scan_was_running(self) -> None:
        # 走査が owner を通り過ぎた後で clone が終わり、一覧を書き終えたのはその 1 秒後。
        # 走査の開始から clone までも 1 秒空け、更新時刻が秒単位のファイルシステムでも前後が決まるようにする
        self.clone("github.com/a/r1")
        self.clone("github.com/z/r9")
        self.stub_ghq(
            """
            scanned=$("$REAL_GHQ" "$@") || exit
            printf '%s\\n' "$scanned" | head -n 1
            sleep 1
            mkdir -p "$GHQ_ROOT/github.com/a/late/.git"
            sleep 1
            printf '%s\\n' "$scanned" | tail -n +2
            """
        )

        proc = self.rebuild()

        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertEqual(self.cache_lines(), ["github.com/a/r1", "github.com/z/r9"])
        self.assertEqual(
            self.list_cached(),
            ["github.com/a/late", "github.com/a/r1", "github.com/z/r9"],
        )

    def test_keeps_the_previous_cache_when_ghq_fails(self) -> None:
        self.cache.write_text("github.com/a/old\n", encoding="utf-8")
        self.stub_ghq(
            """
            echo github.com/a/partial
            exit 1
            """
        )

        self.rebuild()

        self.assertEqual(self.cache_lines(), ["github.com/a/old"])
        self.assertEqual(self.cache_dir_entries(), ["ghq-list"])


class GhqFzfWidgetTest(GhqCacheTestCase):
    """Ctrl+] を押したときに fzf へ渡る一覧。ZLE と fzf は代役に差し替える。"""

    def setUp(self) -> None:
        super().setUp()
        self.env["XDG_CACHE_HOME"] = str(self.cache_dir)
        self.shown = self.base / "shown"

    def press(self) -> list[str]:
        proc = self.zsh(f'zle() {{ :; }}; fzf() {{ cat >| "{self.shown}"; }}; ghq-fzf')
        self.assertEqual(proc.returncode, 0, proc.stderr)
        return self.shown.read_text(encoding="utf-8").splitlines()

    def wait_until(self, done: Callable[[], bool]) -> bool:
        """裏の全走査が終わるのを最大 10 秒待つ。"""
        for _ in range(100):
            if done():
                return True
            time.sleep(0.1)
        return False

    def test_builds_the_cache_on_the_first_press(self) -> None:
        self.clone("github.com/a/r1")

        self.assertEqual(self.press(), ["github.com/a/r1"])
        self.assertEqual(self.cache_lines(), ["github.com/a/r1"])

    def test_shows_a_repo_cloned_since_the_last_scan_right_away(self) -> None:
        self.clone("github.com/a/r1")
        # 10 分以内に全走査したので、裏の全走査は始まらない
        self.build_cache(age=300)

        self.clone("github.com/a/new")

        self.assertEqual(self.press(), ["github.com/a/new", "github.com/a/r1"])
        self.assertEqual(self.cache_lines(), ["github.com/a/r1"])

    def test_rescans_in_the_background_when_the_cache_is_stale(self) -> None:
        self.clone("github.com/a/r1")
        self.build_cache(age=1200)
        # owner 直下より深い階層での追加は、全走査でしか拾えない
        self.clone("github.com/a/wt/feature")

        self.press()

        self.assertTrue(
            self.wait_until(lambda: "github.com/a/wt/feature" in self.cache_lines())
        )
        # 一時ディレクトリを消す前に、裏の全走査が一時ファイルを消し終えるのを待つ
        self.assertTrue(
            self.wait_until(lambda: self.cache_dir_entries() == ["ghq-list"])
        )


if __name__ == "__main__":
    unittest.main()
