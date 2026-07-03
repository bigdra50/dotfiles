---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
---

# TypeScript / JavaScript

型の禁止事項（`any` 等）・スタイルは eslint / tsconfig の設定が正。

## 設計

- class は書かない。関数 + 型で構成する（フレームワークが要求する場合を除く）
- 状態は判別可能 union（discriminated union）で表現する。boolean フラグの組合せで表さない
- データは `readonly` / `Readonly<T>` をデフォルトに
- ID など意味を持つプリミティブは Branded Type にする
- エラーは Result 型（neverthrow）。throw は回復不能な場合のみ
