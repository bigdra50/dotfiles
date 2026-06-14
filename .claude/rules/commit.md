# コミット・PRルール

対象: コミットメッセージ、PRタイトル、PR本文。

## メッセージ言語ポリシー

リモートリポジトリの公開設定に従って言語を切り替える。

| visibility | 言語 |
| ---------- | ---- |
| public     | 英語 |
| private    | 日本語 |
| internal   | 日本語 |
| 判定不能   | 日本語（フォールバック） |

判定方法:

```bash
gh repo view --json visibility -q .visibility
# "PUBLIC" → 英語、"PRIVATE" / "INTERNAL" → 日本語
```

`gh` が使えない・リモート未設定・ネットワーク不通などで判定できない場合は日本語にフォールバックする。
ユーザーが明示的に言語を指定した場合はそれを優先する。

このポリシーはコミットメッセージ、PRタイトル、PR本文すべてに適用する。
type/emoji（`feat`, `fix`, `✨` 等）は言語に関わらず英語のまま。

## Conventional Commit 形式

コミットメッセージは以下の形式に従う：

```
<emoji> <type>: <subject>

<body>
```

### Type と Emoji

| Type     | Emoji | 説明                               |
| -------- | ----- | ---------------------------------- |
| feat     | ✨    | 新機能追加                         |
| fix      | 🐛    | バグ修正                           |
| docs     | 📝    | ドキュメント更新                   |
| style    | 🎨    | フォーマット変更（動作に影響なし） |
| refactor | ♻️    | リファクタリング                   |
| test     | ✅    | テスト追加・修正                   |
| chore    | 🔧    | ビルド・設定ファイル変更           |
| release  | 🔖    | バージョンバンプ・リリース         |
| perf     | ⚡    | パフォーマンス改善                 |
| remove   | 🔥    | コード・ファイル削除               |

## 自動展開の回避

PR / commit 本文で `#N` や `@username` を別の意味で使うと GitHub が自動 link / mention する。
連番は `(1)` `Diagram 1` 等を使い、`#N` を避ける。

作成後の確認:

```bash
gh pr view <N> --json body -q .body | rg -n '(^|[^a-zA-Z0-9])#[0-9]+' && echo "AUTO-LINK"
gh pr view <N> --json body -q .body | rg -n '(^|[^a-zA-Z0-9])@[a-zA-Z0-9_-]+' && echo "MENTION"
```

## HEREDOC

`<<'EOF'`（シングルクオート）を使う。中の特殊文字はエスケープしない。
