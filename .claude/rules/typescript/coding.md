---
paths: "**/*.ts, **/*.tsx, **/*.js, **/*.jsx"
---

# TypeScript / JavaScript

## 型設計

- `type`を優先、`interface`は拡張が必要な場合のみ
- Union型で状態を表現
- Branded Typeで意味のある型を作成
- `as`キャストは最小限
- `any`禁止、`unknown`推奨

## コードスタイル

- 早期リターンで条件分岐をフラット化
- Optional Chainingを活用（`?.`, `??`）
- const assertionで型推論を強化
- 配列操作は`map`, `filter`, `reduce`を優先
- Result型パターンを検討（neverthrow等）。例外は回復不能なエラーのみ
