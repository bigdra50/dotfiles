"""claude-vanilla で起動した Claude Code が、実際に何を読み込むかの仕様。

目印を仕込んだ使い捨てのリポジトリで、各モードを `claude -p` で 1 回ずつ起動する。
そのセッションの transcript と起動時の init メッセージから、
読み込まれた指示ファイル、スキル、エージェント、MCP、hook の実行を検査する。
モデルの自己申告ではなく Claude Code 自身の記録を見るので、結果は決定的になる。

本物の Claude Code と認証を使い、1 モードにつき Haiku で 1 往復ぶんの利用枠を消費する。
そのため CLAUDE_VANILLA_E2E=1 を付けたときだけ走る。
Claude Code を更新したら流し、フラグの意味が変わっていないかを確かめる。

Usage:
    CLAUDE_VANILLA_E2E=1 python3 -m unittest scripts/tests/test_claude_vanilla_e2e.py
"""

from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import tempfile
import unittest
import uuid
from collections import Counter
from dataclasses import dataclass
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[2]
PLUGIN = REPO_ROOT / ".config" / "zsh" / "plugins" / "claude-vanilla.zsh"
CONFIG = Path(os.environ.get("CLAUDE_CONFIG_DIR", Path.home() / ".claude"))
ENABLED = os.environ.get("CLAUDE_VANILLA_E2E") == "1"

PROJECT_SKILL = "e2e-project-skill"
PROJECT_AGENT = "e2e-project-agent"
PROJECT_MCP = "e2e-project-mcp"


def read_json(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError):
        return {}
    return data if isinstance(data, dict) else {}


def user_settings() -> dict[str, Any]:
    return read_json(CONFIG / "settings.json")


def user_skills() -> set[str]:
    """通常起動で有効なユーザースキル（skillOverrides で off のものを除く）。"""
    overrides = user_settings().get("skillOverrides", {})
    return {
        p.parent.name
        for p in CONFIG.glob("skills/*/SKILL.md")
        if overrides.get(p.parent.name) != "off"
    }


def user_agents() -> set[str]:
    names = set()
    for path in CONFIG.glob("agents/*.md"):
        match = re.search(r"^name:\s*(\S+)", path.read_text(), re.MULTILINE)
        names.add(match.group(1) if match else path.stem)
    return names


def user_plugins() -> set[str]:
    enabled = user_settings().get("enabledPlugins", {})
    return {key.split("@")[0] for key, on in enabled.items() if on}


@dataclass(frozen=True)
class Session:
    init: dict[str, Any]
    attachments: list[dict[str, Any]]
    result: dict[str, Any]
    # 実行された hook の名前と回数（ユーザー、プラグイン、プロジェクトを区別しない全件）
    hooks: dict[str, int]
    hook_fired: bool

    def instruction_files(self) -> set[tuple[str, str]]:
        return {
            (f["type"], Path(f["path"]).name)
            for a in self.attachments
            if a.get("type") == "instructions"
            for f in a.get("files", [])
        }

    def instruction_types(self) -> set[str]:
        return {kind for kind, _ in self.instruction_files()}

    def skills(self) -> set[str]:
        return set(self.init.get("skills", []))

    def my_skills(self) -> set[str]:
        return {s.removeprefix("my:") for s in self.skills() if s.startswith("my:")}

    def agents(self) -> set[str]:
        return set(self.init.get("agents", []))

    def contributed_by(self, plugins: set[str]) -> set[str]:
        """プラグインが足したスキルとエージェント（名前に `<plugin>:` が付く）。

        init の plugins 欄は safe mode でも有効化済みプラグインを列挙するが、
        中身は読み込まれない。そのため名前ではなく寄与物の有無で判定する。
        """
        prefixes = tuple(f"{p}:" for p in plugins)
        return {n for n in self.skills() | self.agents() if n.startswith(prefixes)}

    def mcp_servers(self) -> dict[str, str]:
        return {s["name"]: s["source"] for s in self.init.get("mcp_servers", [])}

    def language(self) -> str | None:
        for a in self.attachments:
            if a.get("type") == "language":
                return str(a.get("language"))
        return None

    def system_prompt(self) -> str:
        return "\n".join(
            str(block)
            for a in self.attachments
            if a.get("type") == "prompt_snapshot"
            for block in a.get("systemPrompt", [])
        )


def write_fixture(root: Path, hook_marker: Path) -> None:
    """プロジェクトの各読み込み元に目印を置いたリポジトリを作る。"""
    claude = root / ".claude"
    for sub in ("rules", f"skills/{PROJECT_SKILL}", "agents"):
        (claude / sub).mkdir(parents=True)
    (root / "CLAUDE.md").write_text("MARKER_PROJECT_CLAUDE_MD\n")
    (root / "CLAUDE.local.md").write_text("MARKER_LOCAL_CLAUDE_MD\n")
    (claude / "rules" / "e2e.md").write_text("MARKER_PROJECT_RULE\n")
    (claude / "skills" / PROJECT_SKILL / "SKILL.md").write_text(
        f"---\nname: {PROJECT_SKILL}\ndescription: fixture. Never use.\n---\n"
    )
    (claude / "agents" / f"{PROJECT_AGENT}.md").write_text(
        f"---\nname: {PROJECT_AGENT}\ndescription: fixture. Never use.\n---\n"
    )
    hook = {"type": "command", "command": f"touch {hook_marker}"}
    (claude / "settings.json").write_text(
        json.dumps({"hooks": {"SessionStart": [{"hooks": [hook]}]}})
    )
    (root / ".mcp.json").write_text(
        json.dumps({"mcpServers": {PROJECT_MCP: {"command": "false"}}})
    )
    subprocess.run(["git", "init", "-q"], cwd=root, check=True)


@unittest.skipUnless(ENABLED, "set CLAUDE_VANILLA_E2E=1 (uses the real claude)")
class ClaudeVanillaE2ETest(unittest.TestCase):
    sessions: dict[str, Session]
    tmp: tempfile.TemporaryDirectory[str]
    project: Path
    hook_marker: Path
    transcript_dirs: set[Path]

    @classmethod
    def setUpClass(cls) -> None:
        for tool in ("claude", "zsh", "jq", "git"):
            if shutil.which(tool) is None:
                raise unittest.SkipTest(f"needs {tool}")
        cls.tmp = tempfile.TemporaryDirectory(prefix="claude-vanilla-e2e-")
        cls.project = Path(cls.tmp.name) / "repo"
        cls.project.mkdir()
        cls.hook_marker = Path(cls.tmp.name) / "hook-fired"
        write_fixture(cls.project, cls.hook_marker)
        cls.transcript_dirs = set()
        cls.sessions = {
            "vanilla": cls.launch(),
            "skills": cls.launch("--skills"),
            "project": cls.launch("--project"),
            "project+skills": cls.launch("--project", "--skills"),
        }

    @classmethod
    def tearDownClass(cls) -> None:
        # 使い捨てリポジトリ用に作られたセッション記録だけを消す。
        # 記録のディレクトリ名は、パスの英数字以外を - に置き換えた形になる。
        marker = re.sub(r"[^A-Za-z0-9]", "-", Path(cls.tmp.name).name)
        for path in cls.transcript_dirs:
            if marker in path.name:
                shutil.rmtree(path, ignore_errors=True)
        cls.tmp.cleanup()

    @classmethod
    def launch(cls, *flags: str) -> Session:
        session_id = str(uuid.uuid4())
        cls.hook_marker.unlink(missing_ok=True)
        # 親の Claude Code セッションから流し込まれた環境変数を持ち込まない
        env = {
            k: v
            for k, v in os.environ.items()
            if not k.startswith("CLAUDE") or k == "CLAUDE_CONFIG_DIR"
        }
        claude_args = ["-p", "--model", "haiku", "--session-id", session_id]
        claude_args += ["--output-format", "stream-json", "--verbose"]
        claude_args += ["--include-hook-events"]
        proc = subprocess.run(
            ["zsh", "-f", "-c", 'source "$1"; shift; claude-vanilla "$@"', "zsh"]
            + [str(PLUGIN), *flags, *claude_args],
            cwd=cls.project,
            env=env,
            input="Reply with exactly: OK",
            capture_output=True,
            text=True,
            timeout=300,
            check=False,
        )
        events: list[dict[str, Any]] = [
            json.loads(line) for line in proc.stdout.splitlines() if line
        ]
        init: dict[str, Any] = next(
            (e for e in events if e.get("subtype") == "init"), {}
        )
        result: dict[str, Any] = next(
            (e for e in events if e.get("type") == "result"), {}
        )
        transcripts = list(CONFIG.glob(f"projects/*/{session_id}.jsonl"))
        if proc.returncode != 0 or not init or not transcripts:
            raise AssertionError(
                f"claude-vanilla {flags} failed: {proc.stderr[-2000:]}"
            )
        cls.transcript_dirs.add(transcripts[0].parent)
        attachments = [
            record["attachment"]
            for line in transcripts[0].read_text().splitlines()
            if (record := json.loads(line)).get("type") == "attachment"
        ]
        hooks = Counter(
            str(e.get("hook_name"))
            for e in events
            if e.get("subtype") == "hook_started"
        )
        return Session(init, attachments, result, dict(hooks), cls.hook_marker.exists())

    def test_every_mode_answers(self) -> None:
        for mode, session in self.sessions.items():
            with self.subTest(mode=mode):
                self.assertFalse(session.result.get("is_error"), session.result)

    def test_personal_assets_are_never_loaded(self) -> None:
        for mode, session in self.sessions.items():
            with self.subTest(mode=mode):
                self.assertFalse(
                    {"User", "Local", "AutoMem"} & session.instruction_types()
                )
                self.assertIsNone(session.init.get("memory_paths"))
                self.assertNotIn("# auto memory", session.system_prompt())
                self.assertFalse(user_skills() & session.skills())
                self.assertFalse(user_agents() & session.agents())
                self.assertFalse(session.contributed_by(user_plugins()))
                self.assertEqual(
                    set(session.mcp_servers().values()) - {"project"}, set()
                )

    def test_only_project_hooks_run(self) -> None:
        for mode, session in self.sessions.items():
            project = mode.startswith("project")
            with self.subTest(mode=mode):
                # フィクスチャが持つ hook は SessionStart の 1 件だけ
                self.assertEqual(
                    session.hooks, {"SessionStart:startup": 1} if project else {}
                )
                self.assertEqual(session.hook_fired, project)

    def test_operational_preferences_are_kept(self) -> None:
        language = user_settings().get("language")
        if language is None:
            self.skipTest("no language in user settings")
        for mode, session in self.sessions.items():
            with self.subTest(mode=mode):
                self.assertEqual(session.language(), language)

    def test_project_assets_load_only_with_project(self) -> None:
        for mode, session in self.sessions.items():
            loaded = mode.startswith("project")
            with self.subTest(mode=mode):
                self.assertEqual(
                    session.instruction_files(),
                    {("Project", "CLAUDE.md"), ("Project", "e2e.md")}
                    if loaded
                    else set(),
                )
                self.assertEqual(PROJECT_SKILL in session.skills(), loaded)
                self.assertEqual(PROJECT_AGENT in session.agents(), loaded)
                self.assertEqual(PROJECT_MCP in session.mcp_servers(), loaded)

    def test_user_skills_load_only_with_skills(self) -> None:
        expected = user_skills()
        if not expected:
            self.skipTest("no user skills")
        for mode, session in self.sessions.items():
            with self.subTest(mode=mode):
                wanted = expected if mode.endswith("skills") else set()
                self.assertEqual(session.my_skills(), wanted)


if __name__ == "__main__":
    unittest.main()
