---
paths: "**/*.cs"
---

# C#

## 型設計

- `record`で不変な値オブジェクト
- `readonly struct`でパフォーマンス重視の値型
- `sealed`をデフォルトに
- パターンマッチングを活用

## 命名規則

| 対象 | 規則 | 例 |
|------|------|-----|
| private instance フィールド | `_camelCase` | `_client` |
| private static フィールド | `_camelCase` | `_instance` |
| private static readonly / const | `PascalCase` | `Lock`, `DefaultTimeout` |
| ローカル変数・引数 | `camelCase` | `result`, `hostName` |
| プロパティ・メソッド | `PascalCase` | `IsConnected`, `SendAsync()` |

- ハンガリアン接頭辞(`s_`, `m_`, `t_`)は使わない
- `bool`を`== true`/`== false`で比較しない
- `bool?`にはプロパティパターン(`is not { Prop: true }`)を使う

## コードスタイル

- 早期リターンで条件分岐をフラット化
- `var`は型が明確な場合のみ
- LINQ優先（命令型ループより）
- 式本体メンバーを適切に使用
- Result型パターンを検討。例外は回復不能なエラーのみ
