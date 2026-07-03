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

## ローカル文脈の排除

PR / commit はそれ単体で文脈が完結すべき文書。
ユーザーとClaudeの間でのみ意味を持つ情報を書かない。

書かないもの:

- ローカル作業単位の表記（`Phase N`、`Phase N-M`、`stacked PR の M 件目` 等）。変更の本質を述べる表現に置き換える
- ローカル作業環境の手順（worktree 起動方法、Unity Hub 経由の初回 GUI 起動、NuGet / Library 解決手順、作業ディレクトリ構成、unity-cli の instance 番号等）

書くのは「マージ先を pull する全員」に必要な情報のみ:

- 機能仕様、設計判断、検証結果、実機検証 TODO
- 関連 Issue / PR（`親 PR: #N` のように番号で示す）
- デプロイ時に main 側で要する変更（shared infra 等）

例外・補足:

- ブランチ名は内部識別子として `phase` 等を含んでよい（push 済みブランチのリネームは PR head 変更が必要で影響大）
- 作業単位の追跡が必要なら ADR / docs 内文書で定義して使う。ファイル名にも `Phase` は入れない
- この PR の commit で済ませられる作業（シーン編集・設定追加等）は PR 本文の TODO に残さず commit に含める

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
