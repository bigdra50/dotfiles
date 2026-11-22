"""モジュール定義から chezmoi のソース（home/ 配下）を生成する処理の仕様。"""

from __future__ import annotations

import unittest
from pathlib import Path

import manifest as m
import render as r

REPO_ROOT = Path(__file__).resolve().parents[3]
HOME_DIR = REPO_ROOT / "home"
MANIFEST_PATH = HOME_DIR / ".chezmoidata" / "dotfiles.toml"

PRIVATE = frozenset({".config", ".ssh", ".ssh/config.d"})


class TestSourceName(unittest.TestCase):
    def test_link_at_home_root(self) -> None:
        actual = r.source_name(".zshenv", r.Kind.LINK, PRIVATE)

        self.assertEqual(actual, "symlink_dot_zshenv.tmpl")

    def test_link_under_a_private_dir(self) -> None:
        actual = r.source_name(".config/nvim", r.Kind.LINK, PRIVATE)

        self.assertEqual(actual, "private_dot_config/symlink_nvim.tmpl")

    def test_link_under_a_public_dir(self) -> None:
        actual = r.source_name(".claude/rules", r.Kind.LINK, PRIVATE)

        self.assertEqual(actual, "dot_claude/symlink_rules.tmpl")

    def test_name_without_a_leading_dot_keeps_its_name(self) -> None:
        actual = r.source_name("Documents/PowerShell/profile.ps1", r.Kind.LINK, PRIVATE)

        self.assertEqual(actual, "Documents/PowerShell/symlink_profile.ps1.tmpl")

    def test_json_merge_is_a_private_modify_script(self) -> None:
        actual = r.source_name(".claude/settings.json", r.Kind.MERGE, PRIVATE)

        self.assertEqual(actual, "dot_claude/modify_private_settings.json")

    def test_empty_dir_is_kept_by_a_placeholder(self) -> None:
        actual = r.source_name(".ssh/config.d", r.Kind.DIR, PRIVATE)

        self.assertEqual(actual, "private_dot_ssh/private_config.d/.keep")

    def test_segment_that_chezmoi_would_read_as_an_attribute_is_rejected(self) -> None:
        for target in ("run_me", ".config/private_x", "a/symlink_b", "x.tmpl"):
            with self.subTest(target=target), self.assertRaises(m.ManifestError):
                r.source_name(target, r.Kind.LINK, PRIVATE)


class TestCondition(unittest.TestCase):
    def test_entry_on_every_module_platform_depends_only_on_the_module(self) -> None:
        user = r.User("shell", ("macos", "linux"), module_platforms=("macos", "linux"))

        actual = r.condition([user])

        self.assertEqual(actual, '(has "shell" $on)')

    def test_entry_on_fewer_platforms_also_checks_the_platform(self) -> None:
        user = r.User("git", ("macos",), module_platforms=("macos", "windows"))

        actual = r.condition([user])

        self.assertEqual(actual, '(and (has "git" $on) (has $p (list "macos")))')

    def test_several_users_are_joined_with_or(self) -> None:
        users = [
            r.User("b", ("macos",), module_platforms=("macos",)),
            r.User("a", ("macos",), module_platforms=("macos",)),
            r.User("a", ("macos",), module_platforms=("macos",)),
        ]

        actual = r.condition(users)

        self.assertEqual(actual, '(or (has "a" $on) (has "b" $on))')


class TestRender(unittest.TestCase):
    def setUp(self) -> None:
        self.manifest = m.parse_manifest(
            {
                "dotfiles": {
                    "platforms": ["macos", "windows"],
                    "private_dirs": [".config"],
                    "retired": [".zshrc"],
                    "presets": {"desktop": ["shell", "claude"]},
                    "modules": {
                        "shell": {
                            "platforms": ["macos", "windows"],
                            "links": [
                                {"path": ".zshenv"},
                                {"path": ".config/zsh", "platforms": ["macos"]},
                            ],
                        },
                        "claude": {
                            "platforms": ["macos"],
                            "merges": [{"path": ".claude/settings.json"}],
                        },
                    },
                }
            }
        )
        self.sut = r.render(self.manifest)

    def test_each_link_gets_a_stub_pointing_into_the_working_tree(self) -> None:
        # joinPath は OS の区切り文字で組み立てる。Windows で既存のリンクと同じ文字列になり、
        # chezmoi が張り替えない（張り替えると、管理者所有にした symlink の所有者が戻る）
        self.assertEqual(
            self.sut["symlink_dot_zshenv.tmpl"],
            '{{ joinPath .chezmoi.workingTree ".zshenv" }}\n',
        )
        self.assertEqual(
            self.sut["private_dot_config/symlink_zsh.tmpl"],
            '{{ joinPath .chezmoi.workingTree ".config/zsh" }}\n',
        )

    def test_ignore_lists_each_path_with_the_condition_that_needs_it(self) -> None:
        actual = self.sut[".chezmoiignore"]

        self.assertIn('{{ if not (has "shell" $on) }}\n.zshenv\n{{ end }}', actual)
        self.assertIn(
            '{{ if not (and (has "shell" $on) (has $p (list "macos"))) }}\n'
            ".config/zsh\n{{ end }}",
            actual,
        )

    def test_ignore_drops_a_parent_dir_when_nothing_under_it_is_needed(self) -> None:
        actual = self.sut[".chezmoiignore"]

        self.assertIn(
            '{{ if not (and (has "shell" $on) (has $p (list "macos"))) }}\n'
            ".config\n{{ end }}",
            actual,
        )
        self.assertIn('{{ if not (has "claude" $on) }}\n.claude\n{{ end }}', actual)

    def test_link_table_has_one_row_per_entry(self) -> None:
        rows = [
            line.split("\t")[1:]
            for line in self.sut[".chezmoitemplates/dotfiles/link-table"].splitlines()
            if "\t" in line
        ]

        self.assertEqual(
            rows,
            [
                ["merge", ".claude/settings.json", ".claude/settings.json"],
                ["link", ".config/zsh", ".config/zsh"],
                ["link", ".zshenv", ".zshenv"],
                ["retired", ".zshrc", "-"],
            ],
        )

    def test_every_generated_path_is_owned_by_the_generator(self) -> None:
        for path in self.sut:
            with self.subTest(path=path):
                self.assertTrue(r.is_generated(path))

    def test_hand_written_sources_are_not_owned_by_the_generator(self) -> None:
        for path in (
            ".chezmoi.toml.tmpl",
            ".chezmoidata/dotfiles.toml",
            ".chezmoitemplates/dotfiles/enabled",
            ".chezmoiscripts/run_before_10-backup-conflicts.sh.tmpl",
        ):
            with self.subTest(path=path):
                self.assertFalse(r.is_generated(path))


class TestCommittedSources(unittest.TestCase):
    """home/ にコミットされた生成物が、モジュール定義から作り直したものと一致する。"""

    def setUp(self) -> None:
        self.expected = r.render(m.load_manifest(MANIFEST_PATH))

    def test_generated_files_match_the_manifest(self) -> None:
        for path, content in self.expected.items():
            with self.subTest(path=path):
                target = HOME_DIR / path
                self.assertTrue(target.is_file(), "mise run chezmoi:gen で生成する")
                self.assertEqual(target.read_text(encoding="utf-8"), content)

    def test_no_stale_generated_file_remains(self) -> None:
        actual = {
            path.relative_to(HOME_DIR).as_posix()
            for path in HOME_DIR.rglob("*")
            if path.is_file() and r.is_generated(path.relative_to(HOME_DIR).as_posix())
        }

        self.assertEqual(actual - set(self.expected), set())

    def test_config_template_offers_exactly_the_manifest_presets(self) -> None:
        manifest = m.load_manifest(MANIFEST_PATH)
        template = (HOME_DIR / ".chezmoi.toml.tmpl").read_text(encoding="utf-8")

        actual = r.presets_in_config_template(template)

        self.assertEqual(actual, tuple(sorted(manifest.presets)))


if __name__ == "__main__":
    unittest.main()
