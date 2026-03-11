---
paths: "**/*.py"
---

# Python コーディングルール

## 型設計

- 不変な値オブジェクトは `@dataclass(frozen=True)`
- 依存性逆転は `Protocol`（使用側で定義）
- 辞書の型付けは `TypedDict`

## スタイル

- 早期リターン
- `pathlib.Path` を使う（os.path ではない）
- f-string を使う
- ロギングは structlog 推奨（構造化ログ + bind でコンテキスト付与）
- bare except 禁止。具体的な例外をキャッチして raise

## テスト (pytest)

- テストクラス名: `Test<対象クラス>`、メソッド名: `test_<メソッド>_<条件>_<期待結果>`
- テスト対象は `sut`、実測値は `actual`
- `@pytest.mark.parametrize` を積極的に使う
- fixture でセットアップを共通化

## ツール設定

- ruff: line-length=100, target-version="py312"
- mypy: strict=true
