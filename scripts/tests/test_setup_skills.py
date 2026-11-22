"""apm で skills と agents を入れる処理（scripts/setup/skills.sh）の仕様。

apm は偽物に差し替え、使い捨ての HOME と dotfiles に対して走らせる。
偽物は、この処理が頼っている apm 0.28.0 の挙動だけをまねる。
  - ローカルの agent を各ハーネスへ配置する。配置先に既にファイルがあれば飛ばす
  - install のあとに lock を書く

Usage:
    python3 -m unittest scripts/tests/test_setup_skills.py
"""

from __future__ import annotations

import os
import subprocess
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SKILLS = REPO_ROOT / "scripts" / "setup" / "skills.sh"

# ローカルの agent <name> を apm が配置する先（HOME 相対）
AGENT_TARGETS = (
    ".claude/agents/{name}.md",
    ".codex/agents/{name}.toml",
    ".copilot/agents/{name}.agent.md",
    ".cursor/agents/{name}.md",
)

APM_STUB = r"""#!/usr/bin/env bash
echo "$*" >>"$APM_STUB_LOG"
case "${1:-}" in
    --version)
        echo "Agent Package Manager (APM) CLI version 0.28.0 (stub)"
        ;;
    install)
        for source in "$HOME"/.apm/agents/*.agent.md; do
            [[ -e "$source" ]] || continue
            name="$(basename "$source" .agent.md)"
            for target in ".claude/agents/$name.md" ".codex/agents/$name.toml" \
                ".copilot/agents/$name.agent.md" ".cursor/agents/$name.md"; do
                # 既にあるファイルは「管理外」とみなして上書きしない
                [[ -e "$HOME/$target" ]] && continue
                mkdir -p "$(dirname "$HOME/$target")"
                cp "$source" "$HOME/$target"
            done
        done
        if [[ -n "${APM_STUB_LOCK:-}" ]]; then
            cp "$APM_STUB_LOCK" "$HOME/.apm/apm.lock.yaml"
        fi
        exit "${APM_STUB_EXIT:-0}"
        ;;
esac
"""


def lock(dependencies: dict[str, list[str]]) -> str:
    """apm.lock.yaml のうち、依存ごとの配置済みファイルの部分をまねる。"""
    lines = ["lockfile_version: '1'", "apm_version: 0.28.0", "dependencies:"]
    for name, files in dependencies.items():
        lines += [f"- repo_url: owner/{name}", f"  name: {name}", "  deployed_files:"]
        lines += [f"  - {path}" for path in files]
        lines += ["  deployed_file_hashes:"]
        lines += [f"    {path}: sha256:0" for path in files if "." in Path(path).name]
        lines += ["  content_hash: sha256:0"]
    lines += ["deployments:"]
    for files in dependencies.values():
        for path in files:
            lines += ["- kind: project-relative", f"  value: {path}"]
    return "\n".join(lines) + "\n"


def skill(name: str) -> list[str]:
    return [
        f".agents/skills/{name}",
        f".agents/skills/{name}/SKILL.md",
        f".claude/skills/{name}",
        f".claude/skills/{name}/SKILL.md",
    ]


class SkillsTestCase(unittest.TestCase):
    def setUp(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name).resolve()
        self.home = self.root / "home"
        self.dotfiles = self.root / "dotfiles"
        self.bin = self.root / "bin"
        self.log = self.root / "apm.log"
        for directory in (self.home, self.dotfiles / ".apm" / "agents", self.bin):
            directory.mkdir(parents=True)
        stub = self.bin / "apm"
        stub.write_text(APM_STUB, encoding="utf-8")
        stub.chmod(0o755)
        self.write(self.dotfiles / ".apm" / "apm.yml", "name: test\n")
        self.repo_lock = self.dotfiles / ".apm" / "apm.lock.yaml"
        self.home_lock = self.home / ".apm" / "apm.lock.yaml"
        self.write(self.repo_lock, lock({"kept": skill("kept")}))
        self.stub_env: dict[str, str] = {}

    @staticmethod
    def write(path: Path, content: str) -> Path:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
        return path

    def place(self, *paths: str) -> None:
        """HOME に、配置済みのファイルを置く。"""
        for path in paths:
            if "." in Path(path).name:
                self.write(self.home / path, f"{path}\n")
            else:
                (self.home / path).mkdir(parents=True, exist_ok=True)

    def run_bash(self, script: str) -> subprocess.CompletedProcess[str]:
        env = {
            **os.environ,
            "HOME": str(self.home),
            "PATH": f"{self.bin}{os.pathsep}{os.environ['PATH']}",
            "INTERACTIVE": "false",
            "APM_STUB_LOG": str(self.log),
            **self.stub_env,
        }
        return subprocess.run(
            [
                "bash",
                "-c",
                f'source "{SKILLS}"; DOTFILES_DIR="{self.dotfiles}"; {script}',
            ],
            capture_output=True,
            encoding="utf-8",
            env=env,
            check=False,
        )

    def install(self) -> subprocess.CompletedProcess[str]:
        return self.run_bash("install_skills")

    def apm_calls(self) -> list[str]:
        return (
            self.log.read_text(encoding="utf-8").splitlines()
            if self.log.exists()
            else []
        )


class TestInstall(SkillsTestCase):
    def test_links_the_manifest_and_runs_a_global_install(self) -> None:
        proc = self.install()

        self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
        manifest = self.home / ".apm" / "apm.yml"
        self.assertEqual(os.readlink(manifest), str(self.dotfiles / ".apm" / "apm.yml"))
        self.assertIn("install -g", self.apm_calls())

    def test_installed_lock_is_seeded_from_dotfiles_and_the_old_one_is_kept(
        self,
    ) -> None:
        self.write(self.home_lock, "local resolution\n")

        self.install()

        self.assertEqual(
            self.home_lock.read_text(encoding="utf-8"),
            self.repo_lock.read_text(encoding="utf-8"),
        )
        [kept] = self.home_lock.parent.glob("apm.lock.yaml.detached.*")
        self.assertEqual(kept.read_text(encoding="utf-8"), "local resolution\n")

    def test_lock_written_by_a_successful_install_goes_back_to_dotfiles(self) -> None:
        resolved = self.write(
            self.root / "resolved.lock",
            lock({"kept": skill("kept"), "new": skill("new")}),
        )
        self.stub_env["APM_STUB_LOCK"] = str(resolved)

        proc = self.install()

        self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
        self.assertEqual(
            self.repo_lock.read_text(encoding="utf-8"),
            resolved.read_text(encoding="utf-8"),
        )

    def test_failed_install_fails_and_changes_neither_dotfiles_nor_deployed_files(
        self,
    ) -> None:
        self.write(self.home_lock, lock({"kept": skill("kept"), "gone": skill("gone")}))
        self.place(*skill("gone"))
        before = self.repo_lock.read_text(encoding="utf-8")
        half = self.write(self.root / "half.lock", "half written\n")
        self.stub_env.update(APM_STUB_LOCK=str(half), APM_STUB_EXIT="1")

        proc = self.install()

        self.assertNotEqual(proc.returncode, 0)
        self.assertEqual(self.repo_lock.read_text(encoding="utf-8"), before)
        self.assertTrue((self.home / ".claude/skills/gone/SKILL.md").is_file())

    def test_local_primitives_are_mirrored_without_leftovers(self) -> None:
        self.write(self.dotfiles / ".apm/agents/a.agent.md", "a\n")
        # 以前の setup が写した、今はリポジトリに無いもの
        self.write(self.home / ".apm/agents/old.agent.md", "old\n")
        self.write(self.home / ".apm/hooks/usage-warn-claude-hooks.json", "{}\n")
        self.write(self.home / ".apm/scripts/usage-warn-hook", "#!/bin/sh\n")

        self.install()

        self.assertEqual(
            sorted(path.name for path in (self.home / ".apm/agents").iterdir()),
            ["a.agent.md"],
        )
        self.assertFalse((self.home / ".apm/hooks").exists())
        self.assertFalse((self.home / ".apm/scripts").exists())


class TestDroppedDependencies(SkillsTestCase):
    """別のマシンで外した依存は、取り込んだ lock に載っていない。

    apm は lock に無い配置済みファイルを管理外とみなして残すので、
    適用前の lock と適用後の lock を比べて、消えた分を消す。
    """

    def setUp(self) -> None:
        super().setUp()
        self.write(self.home_lock, lock({"kept": skill("kept"), "gone": skill("gone")}))
        self.place(*skill("kept"), *skill("gone"))

    def test_files_of_a_dependency_that_left_the_lock_are_removed(self) -> None:
        proc = self.install()

        self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
        for path in skill("gone"):
            with self.subTest(path=path):
                self.assertFalse((self.home / path).exists())
        for path in skill("kept"):
            with self.subTest(path=path):
                self.assertTrue((self.home / path).exists())

    def test_files_that_apm_never_deployed_stay(self) -> None:
        mine = self.write(self.home / ".claude/skills/mine/SKILL.md", "mine\n")
        extra = self.write(self.home / ".claude/skills/gone/notes.md", "mine\n")

        self.install()

        self.assertTrue(mine.is_file())
        # 自分で足したファイルが残るディレクトリは消さない
        self.assertTrue(extra.is_file())
        self.assertFalse((self.home / ".claude/skills/gone/SKILL.md").exists())

    def test_paths_that_would_leave_home_are_ignored(self) -> None:
        outside = self.write(self.root / "outside.txt", "keep\n")
        absolute = self.write(self.root / "absolute.txt", "keep\n")
        self.write(
            self.home_lock,
            lock({"kept": skill("kept"), "evil": ["../outside.txt", str(absolute)]}),
        )

        self.install()

        self.assertTrue(outside.is_file())
        self.assertTrue(absolute.is_file())

    def test_lock_deployed_files_lists_the_paths_of_every_dependency(self) -> None:
        proc = self.run_bash(f'lock_deployed_files "{self.home_lock}"')

        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertEqual(proc.stdout.splitlines(), [*skill("kept"), *skill("gone")])


class TestLocalAgents(SkillsTestCase):
    """apm は一度配置したローカルの agent を管理外とみなし、変更にも削除にも追従しない。"""

    def deployed(self, name: str) -> list[Path]:
        return [self.home / target.format(name=name) for target in AGENT_TARGETS]

    def test_changed_agent_replaces_the_deployed_copies(self) -> None:
        self.write(self.dotfiles / ".apm/agents/a.agent.md", "new\n")
        for path in self.deployed("a"):
            self.write(path, "old\n")

        proc = self.install()

        self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
        for path in self.deployed("a"):
            with self.subTest(path=path):
                self.assertEqual(path.read_text(encoding="utf-8"), "new\n")

    def test_agent_deleted_from_dotfiles_loses_its_deployed_copies(self) -> None:
        self.write(self.dotfiles / ".apm/agents/a.agent.md", "a\n")
        self.write(self.home / ".apm/agents/b.agent.md", "b\n")
        for path in self.deployed("b"):
            self.write(path, "b\n")

        self.install()

        for path in self.deployed("b"):
            with self.subTest(path=path):
                self.assertFalse(path.exists())
        self.assertTrue(all(path.is_file() for path in self.deployed("a")))

    def test_agents_that_never_were_local_primitives_stay(self) -> None:
        # 依存のパッケージが配置した agent や、本人が置いた agent
        other = self.write(self.home / ".claude/agents/from-a-package.md", "x\n")

        self.install()

        self.assertTrue(other.is_file())


if __name__ == "__main__":
    unittest.main()
