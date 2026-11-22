"""mise run rdp が sdl-freerdp へ渡す引数の仕様。

対象: .config/mise/tasks/rdp

Usage:
    python3 -m unittest scripts/tests/test_rdp_task.py
"""

from __future__ import annotations

import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
TASK = REPO_ROOT / ".config" / "mise" / "tasks" / "rdp"

# 実物の ssh -G と同じく、設定に無い Host 名は hostname にそのまま出す。
# RequestTTY を設定したマシンでは ssh -G も stderr に警告を出すので、スタブでも出す
SSH_STUB = textwrap.dedent(
    """\
    #!/usr/bin/env bash
    [[ $1 == -G ]] || exit 99
    echo "Pseudo-terminal will not be allocated because stdin is not a terminal." >&2
    [[ -n ${STUB_SSH_FAIL:-} ]] && exit 255
    host=$2
    if [[ -n ${STUB_SSH_MAP:-} && ${STUB_SSH_MAP%%=*} == "$2" ]]; then
        host=${STUB_SSH_MAP#*=}
    fi
    printf 'user someone\\nhostname %s\\nport 22\\n' "$host"
    """
)

# 受け取った引数を NUL 区切りで書き出す
FREERDP_STUB = textwrap.dedent(
    """\
    #!/usr/bin/env bash
    printf '%s\\0' "$@" > "$STUB_ARGV_FILE"
    """
)


def write_stub(path: Path, body: str) -> None:
    path.write_text(body)
    path.chmod(0o755)


class TestRdpTask(unittest.TestCase):
    def setUp(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        base = Path(tmp.name)
        self.bin = base / "bin"
        self.bin.mkdir()
        write_stub(self.bin / "ssh", SSH_STUB)
        write_stub(self.bin / "sdl-freerdp", FREERDP_STUB)
        self.argv_file = base / "argv"
        self.env = {
            "PATH": f"{self.bin}:/usr/bin:/bin",
            "HOME": str(base),
            "STUB_ARGV_FILE": str(self.argv_file),
            "STUB_SSH_MAP": "gamemaster=gm.example.ts.net",
        }

    def run_task(self, *args: str, **env: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["bash", str(TASK), *args],
            capture_output=True,
            text=True,
            env={**self.env, **env},
            check=False,
        )

    def freerdp_argv(self) -> list[str]:
        self.assertTrue(self.argv_file.exists(), "sdl-freerdp が起動していない")
        return self.argv_file.read_text().split("\0")[:-1]

    def test_server_is_hostname_resolved_by_ssh_config(self) -> None:
        cases = {
            "gamemaster": "/v:gm.example.ts.net",
            "not-in-config.local": "/v:not-in-config.local",
        }
        for alias, expected in cases.items():
            with self.subTest(alias=alias):
                result = self.run_task(alias)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn(expected, self.freerdp_argv())

    def test_user_is_passed_only_when_rdp_user_is_non_empty(self) -> None:
        cases: dict[str, dict[str, str]] = {
            "unset": {},
            "empty": {"RDP_USER": ""},
        }
        for name, env in cases.items():
            with self.subTest(rdp_user=name):
                result = self.run_task("gamemaster", **env)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertFalse(
                    [a for a in self.freerdp_argv() if a.startswith("/u:")]
                )

        result = self.run_task("gamemaster", RDP_USER="alice")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("/u:alice", self.freerdp_argv())

    def test_fixed_options_are_always_passed(self) -> None:
        result = self.run_task("gamemaster")
        self.assertEqual(result.returncode, 0, result.stderr)
        argv = self.freerdp_argv()
        self.assertIn("+dynamic-resolution", argv)
        self.assertIn("/from-stdin", argv)

    def test_extra_args_are_appended_in_order(self) -> None:
        extra = ["/size:1280x800", "+clipboard", "/scale:140"]
        result = self.run_task("gamemaster", *extra, RDP_USER="alice")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.freerdp_argv()[-len(extra) :], extra)

    def test_missing_host_prints_usage_and_exits_2(self) -> None:
        result = self.run_task()
        self.assertEqual(result.returncode, 2)
        self.assertIn("Usage:", result.stderr)
        self.assertFalse(self.argv_file.exists())

    def test_help_prints_usage_and_exits_0(self) -> None:
        for flag in ("-h", "--help"):
            with self.subTest(flag=flag):
                result = self.run_task(flag)
                self.assertEqual(result.returncode, 0)
                self.assertIn("Usage:", result.stdout)
                self.assertFalse(self.argv_file.exists())

    def test_missing_client_points_to_brew_install(self) -> None:
        (self.bin / "sdl-freerdp").unlink()
        result = self.run_task("gamemaster")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("brew install freerdp", result.stderr)

    def test_unresolvable_host_names_the_host(self) -> None:
        result = self.run_task("gamemaster", STUB_SSH_FAIL="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("gamemaster", result.stderr)
        self.assertFalse(self.argv_file.exists())


if __name__ == "__main__":
    unittest.main()
