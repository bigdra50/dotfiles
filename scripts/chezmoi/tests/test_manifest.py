"""モジュール定義（home/.chezmoidata/dotfiles.toml）が満たす不変条件の仕様。"""

from __future__ import annotations

import unittest
from pathlib import Path
from typing import Any

import manifest as m

REPO_ROOT = Path(__file__).resolve().parents[3]
MANIFEST_PATH = REPO_ROOT / "home" / ".chezmoidata" / "dotfiles.toml"


def _data(**overrides: Any) -> dict[str, Any]:
    """違反を 1 つだけ仕込めるよう、最小の正しい定義から始める。"""
    dotfiles: dict[str, Any] = {
        "platforms": ["macos", "linux"],
        "private_dirs": [],
        "retired": [],
        "presets": {"desktop": ["shell"]},
        "modules": {
            "shell": {
                "platforms": ["macos", "linux"],
                "links": [{"path": ".zshenv"}],
            }
        },
    }
    dotfiles.update(overrides)
    return {"dotfiles": dotfiles}


def _violations(data: dict[str, Any], existing: set[str] | None = None) -> list[str]:
    sources = {".zshenv"} if existing is None else existing
    return m.check_manifest(m.parse_manifest(data), lambda path: path in sources)


class TestCommittedManifest(unittest.TestCase):
    def test_has_no_violations(self) -> None:
        sut = m.load_manifest(MANIFEST_PATH)

        actual = m.check_manifest(sut, lambda path: (REPO_ROOT / path).exists())

        self.assertEqual(actual, [])


class TestParseManifest(unittest.TestCase):
    def test_path_is_shorthand_for_the_same_target_and_source(self) -> None:
        sut = m.parse_manifest(_data())

        actual = sut.modules[0].links[0]

        self.assertEqual((actual.target, actual.source), (".zshenv", ".zshenv"))

    def test_entry_without_platforms_inherits_the_module_platforms(self) -> None:
        sut = m.parse_manifest(_data())

        self.assertEqual(sut.modules[0].links[0].platforms, ("macos", "linux"))

    def test_entry_with_both_path_and_target_is_rejected(self) -> None:
        data = _data(
            modules={
                "shell": {
                    "platforms": ["macos"],
                    "links": [{"path": ".zshenv", "target": ".zshenv"}],
                }
            }
        )

        with self.assertRaises(m.ManifestError):
            m.parse_manifest(data)

    def test_unknown_key_is_rejected(self) -> None:
        data = _data(
            modules={
                "shell": {
                    "platforms": ["macos"],
                    "links": [{"path": ".zshenv", "plataforms": ["macos"]}],
                }
            }
        )

        with self.assertRaises(m.ManifestError):
            m.parse_manifest(data)


class TestCheckManifest(unittest.TestCase):
    def test_minimal_manifest_has_no_violations(self) -> None:
        self.assertEqual(_violations(_data()), [])

    def test_missing_source_is_reported(self) -> None:
        actual = _violations(_data(), existing=set())

        self.assertEqual(actual, ["shell: source が無い: .zshenv"])

    def test_same_target_in_two_modules_is_reported(self) -> None:
        data = _data(
            modules={
                "shell": {"platforms": ["macos"], "links": [{"path": ".zshenv"}]},
                "other": {"platforms": ["macos"], "links": [{"path": ".zshenv"}]},
            }
        )

        actual = _violations(data)

        self.assertEqual(actual, ["配置先が重複: .zshenv (other, shell)"])

    def test_target_nested_under_another_target_is_reported(self) -> None:
        data = _data(
            modules={
                "shell": {
                    "platforms": ["macos"],
                    "links": [{"path": ".config/zsh"}, {"path": ".config/zsh/.zshrc"}],
                }
            }
        )

        actual = _violations(data, existing={".config/zsh", ".config/zsh/.zshrc"})

        self.assertEqual(
            actual, ["配置先が入れ子: .config/zsh/.zshrc は .config/zsh の内側"]
        )

    def test_module_platform_outside_the_known_set_is_reported(self) -> None:
        data = _data(
            modules={
                "shell": {
                    "platforms": ["macos", "beos"],
                    "links": [{"path": ".zshenv"}],
                }
            }
        )

        actual = _violations(data)

        self.assertEqual(actual, ["shell: 未知の platform: beos"])

    def test_entry_platform_outside_the_module_is_reported(self) -> None:
        data = _data(
            modules={
                "shell": {
                    "platforms": ["macos"],
                    "links": [{"path": ".zshenv", "platforms": ["linux"]}],
                }
            }
        )

        actual = _violations(data)

        self.assertEqual(
            actual, ["shell: .zshenv の platform がモジュールの範囲外: linux"]
        )

    def test_preset_naming_an_unknown_module_is_reported(self) -> None:
        actual = _violations(_data(presets={"desktop": ["shell", "ghost"]}))

        self.assertEqual(actual, ["preset desktop: 未定義のモジュール: ghost"])

    def test_path_escaping_home_is_reported(self) -> None:
        for bad in ("/etc/passwd", "../x", "a/../b", "a//b", "a/", ""):
            with self.subTest(path=bad):
                data = _data(
                    modules={
                        "shell": {
                            "platforms": ["macos"],
                            "links": [{"target": bad, "source": ".zshenv"}],
                        }
                    }
                )

                actual = _violations(data)

                self.assertEqual(actual, [f"shell: 正規化されていないパス: {bad!r}"])

    def test_retired_target_that_is_still_placed_is_reported(self) -> None:
        actual = _violations(_data(retired=[".zshenv"]))

        self.assertEqual(actual, ["retired と配置先が重複: .zshenv"])

    def test_private_dir_that_is_not_a_parent_of_any_entry_is_reported(self) -> None:
        actual = _violations(_data(private_dirs=[".ssh"]))

        self.assertEqual(actual, ["private_dirs が配置先の親ではない: .ssh"])


class TestEnabledModules(unittest.TestCase):
    def setUp(self) -> None:
        self.sut = m.parse_manifest(
            _data(
                presets={"desktop": ["shell", "mac-only"], "server": []},
                modules={
                    "shell": {"platforms": ["macos", "linux"], "links": []},
                    "mac-only": {"platforms": ["macos"], "links": []},
                    "extra": {"platforms": ["linux"], "links": []},
                },
            )
        )

    def test_preset_modules_are_filtered_by_platform(self) -> None:
        actual = m.enabled_modules(self.sut, m.Machine("linux", "desktop"))

        self.assertEqual(actual, frozenset({"shell"}))

    def test_with_adds_and_without_removes(self) -> None:
        machine = m.Machine("linux", "desktop", with_=("extra",), without=("shell",))

        actual = m.enabled_modules(self.sut, machine)

        self.assertEqual(actual, frozenset({"extra"}))

    def test_with_naming_a_module_unsupported_on_the_platform_is_an_error(self) -> None:
        # プリセットの非対応モジュールは黙って外すが、with は本人が名指ししたものなので誤りとして知らせる
        with self.assertRaises(m.ManifestError):
            m.enabled_modules(self.sut, m.Machine("macos", "server", with_=("extra",)))

    def test_unknown_preset_is_an_error(self) -> None:
        with self.assertRaises(m.ManifestError):
            m.enabled_modules(self.sut, m.Machine("macos", "laptop"))

    def test_unknown_module_in_with_or_without_is_an_error(self) -> None:
        for machine in (
            m.Machine("macos", "server", with_=("ghost",)),
            m.Machine("macos", "server", without=("ghost",)),
        ):
            with self.subTest(machine=machine), self.assertRaises(m.ManifestError):
                m.enabled_modules(self.sut, machine)

    def test_unknown_platform_is_an_error(self) -> None:
        with self.assertRaises(m.ManifestError):
            m.enabled_modules(self.sut, m.Machine("beos", "server"))


if __name__ == "__main__":
    unittest.main()
