"""chezmoi apply が HOME に作る状態の仕様。

実物の chezmoi を、使い捨ての配置先・設定・状態ファイルに対して走らせる。
リポジトリの作業ツリーをソースにするが、書き込み先は一時ディレクトリだけ。
"""

from __future__ import annotations

import json
import os
import shutil
import stat
import subprocess
import sys
import tempfile
import tomllib
import unittest
from pathlib import Path
from typing import Any

import manifest as m

REPO_ROOT = Path(__file__).resolve().parents[3]
MANIFEST = m.load_manifest(REPO_ROOT / "home" / ".chezmoidata" / "dotfiles.toml")
CHEZMOI = shutil.which("chezmoi")
PWSH = shutil.which("pwsh")
HOST = m.host_platform()
IS_WINDOWS = sys.platform == "win32"
# chezmoi init が Windows で設定に書く内容（home/.chezmoi.toml.tmpl）と同じ。
# 既定の Windows PowerShell 5.1 では、スクリプトが使う symlink の解決が動かない
WINDOWS_INTERPRETER = (
    ["[interpreters.ps1]", 'command = "pwsh"', 'args = ["-NoLogo", "-NoProfile"]']
    if IS_WINDOWS
    else []
)

# skills を入れるスクリプトが呼ぶ apm の代わり。呼び出しを記録するだけで、何も配置しない。
# 本物を呼ぶと、テストのたびに依存を取得して配置してしまう
APM_STUB = """#!/usr/bin/env bash
echo "$*" >>"$APM_STUB_LOG"
case "${1:-}" in
    --version) echo "Agent Package Manager (APM) CLI version 0.28.0 (stub)" ;;
    install) exit "$(cat "$APM_STUB_EXIT_FILE" 2>/dev/null || echo 0)" ;;
esac
"""
# skills を入れるスクリプトが配置先に作るもの。chezmoi が置くものとは別に数える
SKILLS_SCRIPT_OUTPUTS = (".apm/apm.lock.yaml", ".apm/agents")

# 現行の setup のうち、リンクを張る部分だけを空の HOME に対して走らせる。
LINK_CLAUDE = r"""
source scripts/lib.sh
DOTFILES_DIR="$PWD"; CLAUDE_DIR="$PWD/.claude"
eval "$(sed -n '/^CLAUDE_DIRS=/p;/^CLAUDE_FILES=/p;/^link_claude()/,/^}/p' scripts/setup/claude.sh)"
link_claude
"""


def deep_merge(live: Any, want: Any) -> Any:
    """jq の `live * want` と同じ合成。オブジェクト同士だけを再帰し、ほかは want が勝つ。"""
    if isinstance(live, dict) and isinstance(want, dict):
        merged = dict(live)
        for key, value in want.items():
            merged[key] = deep_merge(live[key], value) if key in live else value
        return merged
    return want


@unittest.skipUnless(CHEZMOI, "chezmoi が無い")
class ApplyTestCase(unittest.TestCase):
    def setUp(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        # macOS の一時ディレクトリは /var -> /private/var の symlink を含む。解決しておく。
        self.root = Path(tmp.name).resolve()
        self.dest = self.root / "home"
        self.dest.mkdir()
        self.state = self.root / "state"
        self.state.mkdir()
        self.config = self.state / "chezmoi.toml"
        # chezmoi を呼ぶ側の HOME。スクリプトは配置先だけを触り、ここには何も書かないはず
        self.caller_home = self.root / "caller-home"
        self.caller_home.mkdir()
        self.bin = self.root / "bin"
        self.bin.mkdir()
        stub = self.bin / "apm"
        stub.write_text(APM_STUB, encoding="utf-8", newline="\n")
        stub.chmod(0o755)
        self.apm_log = self.root / "apm.log"
        self.apm_exit = self.root / "apm.exit"
        self.machine = self.use(preset="desktop")

    def apm_calls(self) -> list[str]:
        if not self.apm_log.exists():
            return []
        return self.apm_log.read_text(encoding="utf-8").splitlines()

    def use(
        self,
        preset: str,
        platform: str = HOST,
        with_: tuple[str, ...] = (),
        without: tuple[str, ...] = (),
    ) -> m.Machine:
        """このマシンの選択を書き換える。chezmoi init が作る設定ファイルと同じ形。"""
        self.config.write_text(
            "\n".join(
                [
                    f"sourceDir = {json.dumps(str(REPO_ROOT))}",
                    "[data.machine]",
                    f"preset = {json.dumps(preset)}",
                    f"with = {json.dumps(list(with_))}",
                    f"without = {json.dumps(list(without))}",
                    f"platform = {json.dumps(platform)}",
                    # 設定を init で作らずに直接書くので、テンプレートとのずれの警告は出さない
                    "[warnings]",
                    "configFileTemplateHasChanged = false",
                    *WINDOWS_INTERPRETER,
                    "",
                ]
            ),
            encoding="utf-8",
        )
        self.machine = m.Machine(platform, preset, with_=with_, without=without)
        return self.machine

    def chezmoi(self, *args: str) -> subprocess.CompletedProcess[str]:
        assert CHEZMOI is not None
        return subprocess.run(
            [
                CHEZMOI,
                "--source",
                str(REPO_ROOT),
                "--destination",
                str(self.dest),
                "--config",
                str(self.config),
                "--persistent-state",
                str(self.state / "state.boltdb"),
                "--cache",
                str(self.state / "cache"),
                "--no-tty",
                *args,
            ],
            capture_output=True,
            encoding="utf-8",
            env={
                **os.environ,
                "HOME": str(self.caller_home),
                "PATH": f"{self.bin}{os.pathsep}{os.environ['PATH']}",
                "APM_STUB_LOG": str(self.apm_log),
                "APM_STUB_EXIT_FILE": str(self.apm_exit),
            },
            check=False,
        )

    def apply(self) -> subprocess.CompletedProcess[str]:
        proc = self.chezmoi("apply")
        self.assertEqual(proc.returncode, 0, proc.stderr)
        return proc

    @staticmethod
    def pointee(link: Path) -> str:
        """symlink の指し先。作業ツリーの中ならリポジトリ相対、外なら絶対パスで返す。"""
        # Windows の readlink は、長いパス用の接頭辞 \\?\ を付けて返すことがある
        text = os.readlink(link).removeprefix("\\\\?\\")
        try:
            # relpath は Windows で大文字と小文字、区切り文字の違いを吸収する
            relative = os.path.relpath(text, REPO_ROOT)
        except ValueError:  # ドライブが違う
            return text
        return text if relative.startswith("..") else Path(relative).as_posix()

    def links(self) -> dict[str, str]:
        """配置先にある symlink を {HOME 相対のパス: 指し先} で返す。"""
        return {
            path.relative_to(self.dest).as_posix(): self.pointee(path)
            for path in self.dest.rglob("*")
            if path.is_symlink()
        }

    def entries(self) -> set[str]:
        """chezmoi が配置先に置いたものすべて。symlink の先はたどらない。"""
        found: set[str] = set()
        for current, dirs, files in os.walk(self.dest, followlinks=False):
            for name in [*dirs, *files]:
                found.add((Path(current) / name).relative_to(self.dest).as_posix())
        return {
            path
            for path in found
            if not any(
                path == output or path.startswith(f"{output}/")
                for output in SKILLS_SCRIPT_OUTPUTS
            )
        }

    def placed(self) -> m.Placements:
        return m.placements(MANIFEST, self.machine)


class TestEnabledTemplate(ApplyTestCase):
    """テンプレート側の選択の計算が、Python のモデルと同じ結果になる。"""

    def enabled(self) -> subprocess.CompletedProcess[str]:
        return self.chezmoi(
            "execute-template", '{{ includeTemplate "dotfiles/enabled" . }}'
        )

    def test_matches_the_model_for_every_platform_and_preset(self) -> None:
        for platform in MANIFEST.platforms:
            for preset in MANIFEST.presets:
                with self.subTest(platform=platform, preset=preset):
                    machine = self.use(preset=preset, platform=platform)

                    proc = self.enabled()

                    self.assertEqual(proc.returncode, 0, proc.stderr)
                    self.assertEqual(
                        frozenset(json.loads(proc.stdout)),
                        m.enabled_modules(MANIFEST, machine),
                    )

    def test_with_and_without_adjust_the_preset(self) -> None:
        machine = self.use(
            preset="server",
            platform="linux",
            with_=("git",),
            without=("claude-skills",),
        )

        proc = self.enabled()

        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertEqual(json.loads(proc.stdout), ["git"])
        self.assertEqual(m.enabled_modules(MANIFEST, machine), frozenset({"git"}))

    def test_mistakes_in_the_machine_config_stop_with_a_message(self) -> None:
        cases = {
            "未定義の preset": {"preset": "laptop"},
            "未定義のモジュール": {"preset": "server", "with_": ("ghost",)},
            "platform に対応しない": {
                "preset": "server",
                "platform": "linux",
                "with_": ("desktop-mac",),
            },
            "未対応の platform": {"preset": "server", "platform": "beos"},
        }
        for message, machine in cases.items():
            with self.subTest(message=message):
                self.use(**machine)  # type: ignore[arg-type]

                proc = self.enabled()

                self.assertNotEqual(proc.returncode, 0)
                self.assertIn(message, proc.stderr)

    def test_platform_is_detected_when_the_config_does_not_force_one(self) -> None:
        text = self.config.read_text(encoding="utf-8")
        self.config.write_text(
            "\n".join(
                line for line in text.splitlines() if not line.startswith("platform")
            ),
            encoding="utf-8",
        )

        proc = self.chezmoi(
            "execute-template", '{{ includeTemplate "dotfiles/platform" . }}'
        )

        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertEqual(proc.stdout, HOST)


class TestApplyLinks(ApplyTestCase):
    def test_places_exactly_what_the_enabled_modules_declare(self) -> None:
        for platform in MANIFEST.platforms:
            for preset in MANIFEST.presets:
                with self.subTest(platform=platform, preset=preset):
                    shutil.rmtree(self.dest)
                    self.dest.mkdir()
                    shutil.rmtree(self.state / "state.boltdb", ignore_errors=True)
                    (self.state / "state.boltdb").unlink(missing_ok=True)
                    self.use(preset=preset, platform=platform)
                    expected = self.placed()

                    self.apply()

                    self.assertEqual(self.links(), dict(expected.links))
                    self.assertEqual(self.entries(), set(expected.entries))

    @unittest.skipIf(IS_WINDOWS, "現行の setup は bash で、Windows を対象にしていない")
    def test_matches_what_the_current_setup_scripts_place(self) -> None:
        # 移行の間だけ意味を持つ検査。現行のスクリプトを消すときに一緒に消す。
        baseline_home = self.root / "baseline"
        baseline_home.mkdir()
        env = {**os.environ, "HOME": str(baseline_home), "INTERACTIVE": "false"}
        for command in (
            ["bash", "scripts/setup/symlinks.sh"],
            ["bash", "-c", LINK_CLAUDE],
        ):
            done = subprocess.run(
                command,
                cwd=REPO_ROOT,
                env=env,
                capture_output=True,
                encoding="utf-8",
                check=False,
            )
            self.assertEqual(done.returncode, 0, done.stderr)
        baseline = {
            path.relative_to(baseline_home).as_posix(): Path(os.readlink(path))
            .relative_to(REPO_ROOT)
            .as_posix()
            for path in baseline_home.rglob("*")
            if path.is_symlink()
        }
        # install_skills が張るリンク。apm の導入を伴うので、ここでは実行せず期待値に足す。
        baseline[".apm/apm.yml"] = ".apm/apm.yml"
        self.use(preset="desktop")

        self.apply()

        self.assertEqual(self.links(), baseline)

    def test_second_apply_changes_nothing(self) -> None:
        self.apply()
        before = {name: (self.dest / name).lstat().st_ino for name in self.entries()}

        proc = self.apply()
        verify = self.chezmoi("verify", "--exclude=always")

        self.assertEqual(proc.stdout, "")
        self.assertEqual(verify.returncode, 0, verify.stderr)
        after = {name: (self.dest / name).lstat().st_ino for name in self.entries()}
        self.assertEqual(after, before)

    def test_link_that_already_points_at_the_source_is_left_alone(self) -> None:
        target = self.dest / ".zshenv"
        target.symlink_to(REPO_ROOT / ".zshenv")
        before = target.lstat().st_ino

        self.apply()

        self.assertEqual(target.lstat().st_ino, before)

    @unittest.skipIf(IS_WINDOWS, "POSIX の権限を検査する")
    def test_parent_dirs_marked_private_are_owner_only(self) -> None:
        self.apply()

        for name in MANIFEST.private_dirs:
            with self.subTest(dir=name):
                mode = stat.S_IMODE((self.dest / name).stat().st_mode)
                self.assertEqual(mode, 0o700)
        self.assertEqual(stat.S_IMODE((self.dest / ".claude").stat().st_mode), 0o755)


class TestBackupConflicts(ApplyTestCase):
    """chezmoi は初回の適用で実体を確認なしに置き換える。その前に退避する。"""

    def backups(self, name: str) -> list[Path]:
        target = self.dest / name
        return sorted(target.parent.glob(f"{target.name}.backup.*"))

    def test_real_file_at_a_link_target_is_kept_as_a_backup(self) -> None:
        (self.dest / ".zshenv").write_text("mine\n", encoding="utf-8")

        self.apply()

        self.assertEqual(self.links()[".zshenv"], ".zshenv")
        [backup] = self.backups(".zshenv")
        self.assertEqual(backup.read_text(encoding="utf-8"), "mine\n")

    def test_real_dir_at_a_link_target_is_kept_with_its_contents(self) -> None:
        mine = self.dest / ".config" / "nvim" / "mine.lua"
        mine.parent.mkdir(parents=True)
        mine.write_text("mine\n", encoding="utf-8")

        self.apply()

        self.assertEqual(self.links()[".config/nvim"], ".config/nvim")
        [backup] = self.backups(".config/nvim")
        self.assertEqual((backup / "mine.lua").read_text(encoding="utf-8"), "mine\n")

    def test_real_file_that_replaced_a_link_later_is_backed_up_too(self) -> None:
        # chezmoi は自分が書いたあとに変わった配置先を見つけると入力を求める。対話なしでも止まらないこと。
        self.apply()
        target = self.dest / ".zshenv"
        target.unlink()
        target.write_text("mine\n", encoding="utf-8")

        self.apply()

        self.assertEqual(self.links()[".zshenv"], ".zshenv")
        [backup] = self.backups(".zshenv")
        self.assertEqual(backup.read_text(encoding="utf-8"), "mine\n")

    def test_symlink_pointing_elsewhere_is_replaced_without_a_backup(self) -> None:
        elsewhere = self.root / "elsewhere"
        elsewhere.write_text("x\n", encoding="utf-8")
        (self.dest / ".zshenv").symlink_to(elsewhere)

        self.apply()

        self.assertEqual(self.links()[".zshenv"], ".zshenv")
        self.assertEqual(self.backups(".zshenv"), [])
        self.assertEqual(elsewhere.read_text(encoding="utf-8"), "x\n")

    @unittest.skipIf(
        IS_WINDOWS, "Windows 用のスクリプトは、親が symlink の配置だけを守る"
    )
    def test_target_that_is_the_source_itself_is_not_moved(self) -> None:
        # 親ディレクトリがリポジトリを指す古い配置では、配置先とソースが同じファイルになる。
        # それを退避するとリポジトリの中身を動かしてしまう。ここでは hard link で同じ状況を作る。
        target = self.dest / ".zshenv"
        try:
            os.link(REPO_ROOT / ".zshenv", target)
        except OSError as error:
            self.skipTest(f"hard link を作れない: {error}")

        self.apply()

        self.assertEqual(self.backups(".zshenv"), [])
        self.assertTrue((REPO_ROOT / ".zshenv").is_file())

    def test_target_of_a_module_that_is_not_enabled_is_not_touched(self) -> None:
        self.use(preset="server")
        mine = self.dest / ".zshenv"
        mine.write_text("mine\n", encoding="utf-8")

        self.apply()

        self.assertFalse(mine.is_symlink())
        self.assertEqual(mine.read_text(encoding="utf-8"), "mine\n")
        self.assertEqual(self.backups(".zshenv"), [])


class TestPruneLinks(ApplyTestCase):
    def test_links_of_a_module_that_was_dropped_are_removed(self) -> None:
        self.apply()
        self.assertIn(".config/nvim", self.links())
        self.use(preset="server")

        self.apply()

        self.assertEqual(self.links(), dict(self.placed().links))

    def test_real_file_at_a_dropped_target_stays(self) -> None:
        self.use(preset="server")
        mine = self.dest / ".vimrc"
        mine.write_text("mine\n", encoding="utf-8")

        self.apply()

        self.assertEqual(mine.read_text(encoding="utf-8"), "mine\n")

    def test_link_to_somewhere_else_at_a_dropped_target_stays(self) -> None:
        self.use(preset="server")
        elsewhere = self.root / "elsewhere"
        elsewhere.write_text("x\n", encoding="utf-8")
        mine = self.dest / ".vimrc"
        mine.symlink_to(elsewhere)

        self.apply()

        self.assertEqual(self.pointee(mine), str(elsewhere))

    def test_dangling_link_at_a_retired_target_is_removed(self) -> None:
        retired = self.dest / ".zshrc"
        retired.symlink_to(REPO_ROOT / "no-longer-here")

        self.apply()

        self.assertFalse(retired.is_symlink())

    def test_live_link_at_a_retired_target_stays(self) -> None:
        elsewhere = self.root / "elsewhere"
        elsewhere.write_text("x\n", encoding="utf-8")
        retired = self.dest / ".zshrc"
        retired.symlink_to(elsewhere)

        self.apply()

        self.assertEqual(self.pointee(retired), str(elsewhere))


class TestSettingsMerge(ApplyTestCase):
    """リポジトリの JSON を live のファイルへ合成する。scripts/lib.sh の merge_json_onto と同じ規則。"""

    def setUp(self) -> None:
        super().setUp()
        self.target = self.dest / ".claude" / "settings.json"
        self.want = json.loads(
            (REPO_ROOT / ".claude" / "settings.json").read_text(encoding="utf-8")
        )

    def write_live(self, path: Path, data: object) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(data), encoding="utf-8")

    def test_missing_target_is_created_readable_only_by_the_owner(self) -> None:
        self.apply()

        self.assertEqual(json.loads(self.target.read_text(encoding="utf-8")), self.want)
        if not IS_WINDOWS:
            self.assertEqual(stat.S_IMODE(self.target.stat().st_mode), 0o600)

    def test_repo_keys_win_and_live_only_keys_stay(self) -> None:
        live = {
            "model": "something-else",
            "sandbox": {"enabled": True, "liveOnly": 1},
            "feedbackSurveyState": {"lastShownTime": 1754086968953},
            "machineLocal": {"effort": "xhigh"},
        }
        self.write_live(self.target, live)

        self.apply()

        actual = json.loads(self.target.read_text(encoding="utf-8"))
        self.assertEqual(actual, deep_merge(live, self.want))
        self.assertEqual(actual["machineLocal"], {"effort": "xhigh"})
        self.assertEqual(actual["sandbox"]["liveOnly"], 1)
        self.assertEqual(actual["sandbox"]["enabled"], self.want["sandbox"]["enabled"])

    def test_target_that_already_contains_the_repo_keys_is_not_rewritten(self) -> None:
        # Claude Code は自分のキー順で書き戻す。意味が同じなら触らない。
        live = dict(reversed(list({**self.want, "machineLocal": 1}.items())))
        self.write_live(self.target, live)
        before = self.target.read_bytes()

        self.apply()

        self.assertEqual(self.target.read_bytes(), before)
        self.assertEqual(self.chezmoi("verify", "--exclude=always").returncode, 0)

    def test_broken_target_stops_the_apply_and_is_left_untouched(self) -> None:
        self.target.parent.mkdir(parents=True)
        self.target.write_text("{broken", encoding="utf-8")

        proc = self.chezmoi("apply")

        self.assertNotEqual(proc.returncode, 0)
        self.assertEqual(self.target.read_text(encoding="utf-8"), "{broken")

    def test_symlink_into_the_repo_becomes_a_real_file(self) -> None:
        self.target.parent.mkdir(parents=True)
        self.target.symlink_to(REPO_ROOT / ".claude" / "settings.json")

        self.apply()

        self.assertFalse(self.target.is_symlink())
        self.assertEqual(json.loads(self.target.read_text(encoding="utf-8")), self.want)

    def test_only_the_listed_keys_are_merged_into_the_cursor_config(self) -> None:
        if not any("cursor" in merge.target for merge in self.placed().merges):
            self.skipTest("cursor モジュールはこの platform を対象にしていない")
        cursor = self.dest / ".config" / "cursor" / "cli-config.json"
        repo = json.loads(
            (REPO_ROOT / ".config" / "cursor" / "cli-config.json").read_text(
                encoding="utf-8"
            )
        )
        live = {"version": 1, "attribution": {"attributeCommitsToAgent": True}}
        self.write_live(cursor, live)

        self.apply()

        actual = json.loads(cursor.read_text(encoding="utf-8"))
        self.assertEqual(actual["attribution"], repo["attribution"])
        self.assertEqual(set(actual), {"version", "attribution"})

    def test_cursor_config_is_not_created_before_cursor_writes_one(self) -> None:
        self.apply()

        self.assertFalse(
            (self.dest / ".config" / "cursor" / "cli-config.json").exists()
        )

    def test_settings_of_a_module_that_is_not_enabled_are_not_touched(self) -> None:
        self.use(preset="server")
        self.write_live(self.target, {"model": "mine"})
        before = self.target.read_bytes()

        self.apply()

        self.assertEqual(self.target.read_bytes(), before)


@unittest.skipIf(
    IS_WINDOWS, "skills を入れる処理は bash で、Windows は対象にしていない"
)
class TestInstallSkillsScript(ApplyTestCase):
    """chezmoi が、skills を入れる処理（scripts/setup/skills.sh）を必要なときだけ呼ぶ。

    処理そのものの仕様は scripts/tests/test_setup_skills.py にある。
    """

    INSTALL = "install -g"

    def test_runs_once_and_not_again_while_its_inputs_are_unchanged(self) -> None:
        self.apply()
        self.apply()

        self.assertEqual(self.apm_calls().count(self.INSTALL), 1)

    def test_works_on_the_destination_and_leaves_the_callers_home_alone(self) -> None:
        self.apply()

        # 取り込んだ lock を配置先へ写すのは、この処理の最初の仕事
        self.assertTrue((self.dest / ".apm" / "apm.lock.yaml").is_file())
        self.assertEqual(list(self.caller_home.iterdir()), [])

    def test_does_not_run_when_the_module_is_not_enabled(self) -> None:
        self.use(preset="desktop", without=("claude-skills",))

        self.apply()

        self.assertNotIn(self.INSTALL, self.apm_calls())

    def test_failed_install_fails_the_apply_and_is_tried_again(self) -> None:
        self.apm_exit.write_text("1", encoding="utf-8")

        failed = self.chezmoi("apply")
        self.apm_exit.write_text("0", encoding="utf-8")
        self.apply()

        self.assertNotEqual(failed.returncode, 0)
        self.assertEqual(self.apm_calls().count(self.INSTALL), 2)


class TestInit(ApplyTestCase):
    """chezmoi init が、マシンごとの設定ファイルを対話なしで作れる。"""

    def read_config(self) -> dict[str, Any]:
        with self.config.open("rb") as file:
            return tomllib.load(file)

    def test_writes_the_chosen_preset_and_the_source_location(self) -> None:
        self.config.unlink()

        proc = self.chezmoi("init", "--promptChoice", "preset=server")

        self.assertEqual(proc.returncode, 0, proc.stderr)
        actual = self.read_config()
        self.assertEqual(
            actual["data"]["machine"],
            {"preset": "server", "with": [], "without": []},
        )
        self.assertEqual(Path(actual["sourceDir"]), REPO_ROOT)

    def test_keeps_the_existing_selection_when_run_again(self) -> None:
        self.use(preset="server", with_=("git",), without=("claude-skills",))

        proc = self.chezmoi("init")

        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertEqual(
            self.read_config()["data"]["machine"],
            {"preset": "server", "with": ["git"], "without": ["claude-skills"]},
        )

    def test_generated_config_applies_without_warnings(self) -> None:
        self.config.unlink()
        self.chezmoi("init", "--promptChoice", "preset=server")

        proc = self.chezmoi("apply")
        status = self.chezmoi("status")
        verify = self.chezmoi("verify")

        self.assertEqual((proc.returncode, proc.stderr), (0, ""))
        # 毎回走るスクリプトは、設定の exclude で差分の表示と検査から外れる
        self.assertEqual((status.returncode, status.stdout), (0, ""))
        self.assertEqual(verify.returncode, 0, verify.stderr)


@unittest.skipIf(IS_WINDOWS, "bash のスクリプトを検査する")
@unittest.skipUnless(shutil.which("shellcheck"), "shellcheck が無い")
class TestScripts(ApplyTestCase):
    """スクリプトはテンプレートなので、描画した結果を検査する。"""

    def test_rendered_scripts_pass_shellcheck(self) -> None:
        scripts = sorted((REPO_ROOT / "home" / ".chezmoiscripts").glob("*.sh.tmpl"))
        self.assertTrue(scripts)
        for script in scripts:
            with self.subTest(script=script.name):
                rendered = self.chezmoi(
                    "execute-template", script.read_text(encoding="utf-8")
                )
                self.assertEqual(rendered.returncode, 0, rendered.stderr)

                lint = subprocess.run(
                    ["shellcheck", "-S", "warning", "-"],
                    input=rendered.stdout,
                    capture_output=True,
                    encoding="utf-8",
                    check=False,
                )

                self.assertEqual(lint.returncode, 0, lint.stdout)


@unittest.skipUnless(PWSH, "pwsh が無い")
@unittest.skipIf(IS_WINDOWS, "Windows では chezmoi apply がこのスクリプトを実行する")
class TestPowerShellScripts(ApplyTestCase):
    """Windows 用のスクリプトが、bash 版と同じ規則で退避と掃除をする。

    chezmoi は OS に合う形式のスクリプトだけを実行するので、Windows 以外では
    描画した結果を pwsh で直接走らせて確かめる。
    """

    BACKUP = "run_before_10-backup-conflicts.ps1.tmpl"
    PRUNE = "run_after_90-prune-links.ps1.tmpl"

    def run_script(self, name: str) -> subprocess.CompletedProcess[str]:
        assert PWSH is not None
        template = REPO_ROOT / "home" / ".chezmoiscripts" / name
        rendered = self.chezmoi(
            "execute-template", template.read_text(encoding="utf-8")
        )
        self.assertEqual(rendered.returncode, 0, rendered.stderr)
        script = self.root / name.removesuffix(".tmpl")
        script.write_text(rendered.stdout, encoding="utf-8")
        proc = subprocess.run(
            [PWSH, "-NoLogo", "-NoProfile", "-File", str(script)],
            capture_output=True,
            encoding="utf-8",
            check=False,
        )
        self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
        return proc

    def backups(self, name: str) -> list[Path]:
        target = self.dest / name
        return sorted(target.parent.glob(f"{target.name}.backup.*"))

    def test_backup_keeps_a_real_file_and_links_the_target(self) -> None:
        (self.dest / ".zshenv").write_text("mine\n", encoding="utf-8")

        self.run_script(self.BACKUP)

        self.assertEqual(self.links()[".zshenv"], ".zshenv")
        [backup] = self.backups(".zshenv")
        self.assertEqual(backup.read_text(encoding="utf-8"), "mine\n")

    def test_backup_keeps_a_real_dir_with_its_contents(self) -> None:
        mine = self.dest / ".config" / "nvim" / "mine.lua"
        mine.parent.mkdir(parents=True)
        mine.write_text("mine\n", encoding="utf-8")

        self.run_script(self.BACKUP)

        self.assertEqual(self.links()[".config/nvim"], ".config/nvim")
        [backup] = self.backups(".config/nvim")
        self.assertEqual((backup / "mine.lua").read_text(encoding="utf-8"), "mine\n")

    def test_backup_leaves_symlinks_and_disabled_targets_alone(self) -> None:
        self.use(preset="server")
        elsewhere = self.root / "elsewhere"
        elsewhere.write_text("x\n", encoding="utf-8")
        (self.dest / ".apm").mkdir()
        (self.dest / ".apm" / "apm.yml").symlink_to(elsewhere)
        (self.dest / ".zshenv").write_text("mine\n", encoding="utf-8")

        self.run_script(self.BACKUP)

        self.assertEqual(self.pointee(self.dest / ".apm" / "apm.yml"), str(elsewhere))
        self.assertFalse((self.dest / ".zshenv").is_symlink())
        self.assertEqual(self.backups(".zshenv") + self.backups(".apm/apm.yml"), [])

    def test_backup_does_not_move_a_target_reached_through_a_linked_parent(
        self,
    ) -> None:
        # 親ディレクトリが symlink なら、配置先はその先の実体。動かすと他人の持ち物を動かす。
        real = self.root / "real-config"
        (real / "nvim").mkdir(parents=True)
        (self.dest / ".config").symlink_to(real)

        self.run_script(self.BACKUP)

        self.assertTrue((real / "nvim").is_dir())
        self.assertEqual(sorted(path.name for path in real.iterdir()), ["nvim"])

    def test_prune_removes_only_links_into_the_tree_and_dangling_ones(self) -> None:
        self.apply()
        self.use(preset="server")
        elsewhere = self.root / "elsewhere"
        elsewhere.write_text("x\n", encoding="utf-8")
        vimrc = self.dest / ".vimrc"
        vimrc.unlink()
        vimrc.symlink_to(elsewhere)
        zshenv = self.dest / ".zshenv"
        zshenv.unlink()
        zshenv.write_text("mine\n", encoding="utf-8")
        retired_dangling = self.dest / ".zshrc"
        retired_dangling.symlink_to(REPO_ROOT / "no-longer-here")
        retired_live = self.dest / ".Brewfile"
        retired_live.symlink_to(elsewhere)

        self.run_script(self.PRUNE)

        expected = {**self.placed().links, ".vimrc": str(elsewhere)}
        expected[".Brewfile"] = str(elsewhere)
        self.assertEqual(self.links(), expected)
        self.assertEqual(zshenv.read_text(encoding="utf-8"), "mine\n")


if __name__ == "__main__":
    unittest.main()
