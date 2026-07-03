---
paths:
  - "**/*.cs"
---

# C#

フォーマット・命名の機械検査可能な部分は .editorconfig / analyzer の設定が正。以下は標準からの逸脱と選択のみ。

## 命名（.NET runtime 標準からの逸脱）

- private static フィールドも `_camelCase`（`s_` / `m_` / `t_` 接頭辞は使わない）
- private static readonly / const は `PascalCase`（例: `Lock`, `DefaultTimeout`）

## 設計

- クラス継承は書かない。振る舞いの共有は composition と interface で（フレームワーク要求を除く）
- 値オブジェクトは `record`、型は `sealed` をデフォルトに
- エラーは Result 型パターン。例外は回復不能な場合のみ
- `bool?` はプロパティパターン（`is not { Prop: true }`）で判定する
