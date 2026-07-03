---
paths:
  - "**/*.py"
---

# Python

フォーマット・import 順・禁止構文は ruff / mypy の設定が正。ここには lint で表現できない判断のみ書く。

## パッケージ管理・実行 (uv)

- 依存追加は `uv add`、実行は `uv run`。pip / poetry / venv を直接操作しない
- 単発スクリプトは PEP 723 inline metadata を付けて `uv run script.py`
- ツールの一時実行は `uvx`

## 設計

- ロジックはモジュールレベルの純粋関数で書く。クラスは状態と振る舞いを束ねる必要がある場合のみ
- 継承は書かない。抽象は `Protocol`（使用側で定義）、ABC 継承より Protocol を優先
- 値オブジェクトは `@dataclass(frozen=True)`。可変にする明確な理由がない限り frozen
- 辞書をそのまま受け渡さない。`TypedDict` か dataclass で型を付ける
- ロギングは structlog（構造化ログ + `bind` でコンテキスト付与）

## テスト (pytest)

- テストクラス: `Test<対象>`、メソッド: `test_<メソッド>_<条件>_<期待結果>`
- テスト対象は `sut`、実測値は `actual`
- 類似ケースは `@pytest.mark.parametrize` にまとめる
- セットアップの共通化は fixture で行う
