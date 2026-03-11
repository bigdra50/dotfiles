---
paths:
  - "**/*.go"
  - "**/*.rs"
  - "**/*.ts"
  - "**/*.lua"
  - "**/*.cs"
---

# 設計共通ルール

- SOLID原則に従う
- 関数型アプローチを優先: 純粋関数、不変データ構造、副作用の分離（Functional Core, Imperative Shell）
- YAGNI: 現在必要な機能のみ実装。未使用コードは即削除。意図不明なコードは変更前にユーザーに確認

## 命名規則

`check`、`process`、`handle`、`do` のような曖昧な動詞を避け、具体的なアクションを使う:

- CompareVersion / ValidateInput / FetchLatestData
- 戻り値型も同様: VersionCompareResult, ParsedConfig（CheckResult, Data は避ける）
