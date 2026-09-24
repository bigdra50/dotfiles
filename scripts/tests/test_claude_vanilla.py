"""claude-vanilla（.config/zsh/plugins/claude-vanilla.zsh）の仕様。

本物の claude の代わりに、受け取った引数と環境変数を記録するスタブを PATH に置く。
起動モードごとに、claude へ何が渡るかを検査する。
渡したフラグで Claude Code が実際に何を読み込むかは test_claude_vanilla_e2e.py が検査する。

Usage:
    python3 -m unittest scripts/tests/test_claude_vanilla.py
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import tempfile
import unittest
from dataclasses import dataclass
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
PLUGIN = REPO_ROOT / ".config" / "zsh" / "plugins" / "claude-vanilla.zsh"

STUB = """#!/usr/bin/env python3
import json, os, sys
with open(os.environ["CLAUDE_STUB_OUT"], "w") as f:
    json.dump({"args": sys.argv[1:], "env": dict(os.environ)}, f)
sys.exit(int(os.environ.get("CLAUDE_STUB_EXIT", "0")))
"""

USER_SETTINGS = {
    "model": "opus[1m]",
    "effortLevel": "xhigh",
    "language": "Japanese",
    "env": {"CLAUDE_CODE_EFFORT_LEVEL": "max"},
    "permissions": {"allow": ["Read"], "defaultMode": "auto"},
    "statusLine": {"type": "command", "command": "status"},
    "skillOverrides": {"skill-off": "off"},
    "hooks": {"Stop": [{"hooks": [{"type": "command", "command": "x"}]}]},
    "enabledPlugins": {"codex@openai-codex": True},
    "extraKnownMarketplaces": {"m": {"source": {"source": "github", "repo": "a/b"}}},
    "mcpServers": {"notion": {"url": "https://mcp.notion.com/mcp"}},
    "outputStyle": "Explanatory",
    "agent": "reviewer",
}

# 操作系の好み。モデルへの指示にならないので引き継ぐ側
CARRIED_KEYS = {
    "model",
    "effortLevel",
    "language",
    "env",
    "permissions",
    "statusLine",
    "skillOverrides",
}
# プロンプトや拡張を持ち込む分類（safe mode が無効化する分類）。引き継がない側
DROPPED_KEYS = {
    "hooks",
    "enabledPlugins",
    "extraKnownMarketplaces",
    "mcpServers",
    "outputStyle",
    "agent",
}


@dataclass(frozen=True)
class Launch:
    returncode: int
    args: list[str]
    env: dict[str, str]
    stdout: str


def option_value(args: list[str], name: str) -> str:
    """`--name value` の value を返す。無ければ AssertionError。"""
    assert name in args, f"{name} not in {args}"
    return args[args.index(name) + 1]


@unittest.skipUnless(shutil.which("zsh") and shutil.which("jq"), "needs zsh and jq")
class ClaudeVanillaTestCase(unittest.TestCase):
    def setUp(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name)
        self.home = self.root / "home"
        self.config = self.home / ".claude"
        self.cache = self.root / "cache"
        self.stub_dir = self.root / "stub"
        self.out = self.root / "claude-call.json"
        self.config.mkdir(parents=True)
        self.stub_dir.mkdir()
        stub = self.stub_dir / "claude"
        stub.write_text(STUB)
        stub.chmod(0o755)
        (self.config / "settings.json").write_text(json.dumps(USER_SETTINGS))
        for name in ("skill-a", "skill-off"):
            self.add_skill(name)
        # SKILL.md の無いディレクトリはスキルではない
        (self.config / "skills" / "not-a-skill").mkdir()
        # apm は実体を置くが、手で置いたスキルがシンボリックリンクのこともある
        linked = self.root / "elsewhere" / "skill-linked"
        linked.mkdir(parents=True)
        (linked / "SKILL.md").write_text("---\nname: skill-linked\n---\n")
        (self.config / "skills" / "skill-linked").symlink_to(linked)

    def add_skill(self, name: str) -> Path:
        path = self.config / "skills" / name
        path.mkdir(parents=True)
        (path / "SKILL.md").write_text(f"---\nname: {name}\n---\n")
        return path

    def run_zsh(self, script: str, *args: str, exit_code: int = 0) -> Launch:
        env = {
            "HOME": str(self.home),
            "PATH": f"{self.stub_dir}{os.pathsep}{os.environ['PATH']}",
            "XDG_CACHE_HOME": str(self.cache),
            "CLAUDE_STUB_OUT": str(self.out),
            "CLAUDE_STUB_EXIT": str(exit_code),
        }
        if self.out.exists():
            self.out.unlink()
        proc = subprocess.run(
            ["zsh", "-f", "-c", f'source "$1"; shift; {script}', "zsh", str(PLUGIN)]
            + list(args),
            env=env,
            capture_output=True,
            text=True,
            check=False,
        )
        call = json.loads(self.out.read_text()) if self.out.exists() else {}
        return Launch(
            returncode=proc.returncode,
            args=call.get("args", []),
            env=call.get("env", {}),
            stdout=proc.stdout,
        )

    def launch(self, *args: str, exit_code: int = 0) -> Launch:
        launch = self.run_zsh('claude-vanilla "$@"', *args, exit_code=exit_code)
        self.assertTrue(self.out.exists(), "claude was not called")
        return launch

    def plugin_dir(self, launch: Launch) -> Path:
        return Path(option_value(launch.args, "--plugin-dir"))

    def carried_settings(self, launch: Launch) -> dict[str, object]:
        settings = json.loads(Path(option_value(launch.args, "--settings")).read_text())
        assert isinstance(settings, dict)
        return settings


class VanillaTest(ClaudeVanillaTestCase):
    """オプション無しは公式の safe mode に任せる。"""

    def test_uses_official_safe_mode(self) -> None:
        self.assertEqual(self.launch().args, ["--safe-mode"])

    def test_passes_other_arguments_through(self) -> None:
        launch = self.launch("--dangerously-skip-permissions", "-c")
        self.assertEqual(
            launch.args, ["--safe-mode", "--dangerously-skip-permissions", "-c"]
        )

    def test_generates_nothing(self) -> None:
        self.launch()
        self.assertFalse((self.cache / "claude-vanilla").exists())

    def test_propagates_exit_status(self) -> None:
        self.assertEqual(self.launch(exit_code=3).returncode, 3)


class SkillsTest(ClaudeVanillaTestCase):
    """--skills は読み込み元を全部外し、~/.claude/skills だけを足す。"""

    def test_loads_no_setting_source(self) -> None:
        launch = self.launch("--skills")
        self.assertEqual(option_value(launch.args, "--setting-sources"), "")
        self.assertIn("--strict-mcp-config", launch.args)
        self.assertNotIn("--safe-mode", launch.args)

    def test_disables_memory_claude_md_and_claude_ai_connectors(self) -> None:
        env = self.launch("--skills").env
        self.assertEqual(env.get("CLAUDE_CODE_DISABLE_AUTO_MEMORY"), "1")
        self.assertEqual(env.get("CLAUDE_CODE_DISABLE_CLAUDE_MDS"), "1")
        self.assertEqual(env.get("ENABLE_CLAUDEAI_MCP_SERVERS"), "false")

    def test_environment_does_not_leak_into_calling_shell(self) -> None:
        launch = self.run_zsh(
            'claude-vanilla --skills; print -r -- "${CLAUDE_CODE_DISABLE_AUTO_MEMORY-unset}"'
        )
        self.assertEqual(launch.stdout.strip(), "unset")

    def test_wraps_user_skills_as_plugin_named_my(self) -> None:
        plugin = self.plugin_dir(self.launch("--skills"))
        manifest = json.loads((plugin / ".claude-plugin" / "plugin.json").read_text())
        self.assertEqual(manifest["name"], "my")
        link = plugin / "skills" / "skill-a"
        self.assertTrue(link.is_symlink())
        self.assertEqual(link.resolve(), (self.config / "skills" / "skill-a").resolve())

    def test_includes_symlinked_skills(self) -> None:
        plugin = self.plugin_dir(self.launch("--skills"))
        self.assertTrue((plugin / "skills" / "skill-linked" / "SKILL.md").is_file())

    def test_excludes_skills_turned_off_and_non_skill_dirs(self) -> None:
        plugin = self.plugin_dir(self.launch("--skills"))
        names = sorted(p.name for p in (plugin / "skills").iterdir())
        self.assertEqual(names, ["skill-a", "skill-linked"])

    def test_follows_changes_to_skills_dir(self) -> None:
        self.launch("--skills")
        shutil.rmtree(self.config / "skills" / "skill-a")
        self.add_skill("skill-new")
        plugin = self.plugin_dir(self.launch("--skills"))
        names = sorted(p.name for p in (plugin / "skills").iterdir())
        self.assertEqual(names, ["skill-linked", "skill-new"])

    def test_carries_operational_preferences_only(self) -> None:
        self.assertEqual(set(USER_SETTINGS), CARRIED_KEYS | DROPPED_KEYS)
        settings = self.carried_settings(self.launch("--skills"))
        self.assertEqual(set(settings), CARRIED_KEYS)
        self.assertEqual(settings["model"], "opus[1m]")

    def test_generated_files_live_in_xdg_cache(self) -> None:
        launch = self.launch("--skills")
        cache = self.cache / "claude-vanilla"
        self.assertTrue(self.plugin_dir(launch).is_relative_to(cache))
        self.assertTrue(
            Path(option_value(launch.args, "--settings")).is_relative_to(cache)
        )

    def test_launches_without_user_settings(self) -> None:
        (self.config / "settings.json").unlink()
        launch = self.launch("--skills")
        self.assertNotIn("--settings", launch.args)
        self.assertEqual(launch.returncode, 0)

    def test_own_options_are_recognized_anywhere(self) -> None:
        launch = self.launch("-c", "--skills", "--dangerously-skip-permissions")
        self.assertNotIn("--skills", launch.args)
        self.assertIn("--plugin-dir", launch.args)
        self.assertEqual(launch.args[-2:], ["-c", "--dangerously-skip-permissions"])

    def test_arguments_after_double_dash_are_passed_verbatim(self) -> None:
        launch = self.launch("-p", "--", "--skills")
        self.assertEqual(launch.args, ["--safe-mode", "-p", "--", "--skills"])


class ProjectTest(ClaudeVanillaTestCase):
    """--project は個人の資産を外し、リポジトリの共有設定だけ読む。"""

    def test_loads_project_scope_only(self) -> None:
        launch = self.launch("--project")
        self.assertEqual(option_value(launch.args, "--setting-sources"), "project")
        self.assertNotIn("--strict-mcp-config", launch.args)
        self.assertNotIn("--plugin-dir", launch.args)
        self.assertNotIn("--safe-mode", launch.args)

    def test_keeps_claude_md_but_drops_memory_and_claude_ai_connectors(self) -> None:
        env = self.launch("--project").env
        self.assertNotIn("CLAUDE_CODE_DISABLE_CLAUDE_MDS", env)
        self.assertEqual(env.get("CLAUDE_CODE_DISABLE_AUTO_MEMORY"), "1")
        self.assertEqual(env.get("ENABLE_CLAUDEAI_MCP_SERVERS"), "false")

    def test_carries_operational_preferences_only(self) -> None:
        settings = self.carried_settings(self.launch("--project"))
        self.assertEqual(set(settings), CARRIED_KEYS)


class ChromeTest(ClaudeVanillaTestCase):
    """Chrome 連携は ~/.claude.json の既定値で有効になり、setting sources では外れない。"""

    def test_disabled_in_modes_without_safe_mode(self) -> None:
        for flag in ("--skills", "--project"):
            with self.subTest(flag=flag):
                self.assertIn("--no-chrome", self.launch(flag).args)

    def test_can_be_reenabled_by_passing_chrome(self) -> None:
        # claude は同じオプションの後勝ちなので、利用者の --chrome が後ろに来ればよい
        args = self.launch("--skills", "--chrome").args
        self.assertLess(args.index("--no-chrome"), args.index("--chrome"))


class CombinedTest(ClaudeVanillaTestCase):
    def test_project_with_skills(self) -> None:
        launch = self.launch("--project", "--skills")
        self.assertEqual(option_value(launch.args, "--setting-sources"), "project")
        self.assertIn("--plugin-dir", launch.args)
        self.assertNotIn("CLAUDE_CODE_DISABLE_CLAUDE_MDS", launch.env)

    def test_option_order_does_not_matter(self) -> None:
        first = self.launch("--skills", "--project").args
        second = self.launch("--project", "--skills").args
        self.assertEqual(first, second)


if __name__ == "__main__":
    unittest.main()
