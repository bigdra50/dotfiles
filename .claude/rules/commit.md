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

## コミット条件

以下のすべての条件が満たされた場合のみコミットする：

1. **すべてのテストが通過している** - 例外なし
2. **すべてのコンパイラ/リンター警告が解決されている**
3. **変更が単一の論理的な作業単位を表している**

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

## コミットの原則

- 大きく頻度の低いコミットより、小さく頻繁なコミットを使用
- 各コミットは機能を壊さずに元に戻せること
- 作業中のコードをコミットしない
- コミットは単一の目的に集中させる
- 複数の関心事がある場合は、それぞれ個別にコミット

## 複数の関心事がある場合

異なる関心事が混在している場合は、関心事ごとにコミットを分割：

```
# 例：以下の関心事が混在
- 新機能追加（feat）
- ドキュメント更新（docs）
- テスト追加（test）

# 分割してコミット（public想定: 英語）
1st: ✨ feat: add new feature
2nd: 📝 docs: update documentation
3rd: ✅ test: add unit tests

# 分割してコミット（private想定: 日本語）
1st: ✨ feat: 新機能を追加
2nd: 📝 docs: ドキュメントを更新
3rd: ✅ test: ユニットテストを追加
```

## 自動展開・自動 link の罠

GitHub Markdown / Slack 等は本文中の一部表記を勝手に展開・リンク化する。
PR / Issue / Comment / Commit message を書くとき、無自覚に意図しない展開を発生させない。

### `#N` は自動で issue/PR link になる

GitHub の Markdown は本文中の `#1` `#42` 等を「同リポジトリの issue/PR #N」へのリンクとして自動展開する。
別の意味で使うと意図しない issue が引用される。

| 用途 | ❌ 自動 link 化されてしまう | ✅ 自動 link を避ける |
|------|------|------|
| 図の連番 | `## #1 構成図` | `## Diagram 1: 構成図` / `## (1) 構成図` |
| カテゴリ番号 | `## #2 重複削減` | `## カテゴリ 2: 重複削減` |
| 順序付きアイテム | `- #1 から確認` | `- 1 番目から確認` / `- まず ① から` |

連番がどうしても必要なら `Diagram N` / `(N)` / `① ② ③` を使う。
バッククォートで囲む `` `#1` `` でもコードフォントになるが、見出しに使うと不自然。

### その他の自動展開

| パターン | 自動化される挙動 | 回避策 |
|---------|-----------------|--------|
| `@username` | user mention で通知が飛ぶ | バッククォートで囲む or 文脈を変える |
| `username/repo#N` | クロスリポジトリ issue link | バッククォートで囲む |
| `<URL>` (素の URL) | リンク化される (望ましい場合が多い) | コードとして見せたいときだけバッククォート |
| `[[wiki link]]` | (一部プラットフォーム) wiki page link | 二重角括弧を避ける |

### 確認手順

PR / commit 作成直後に必ず:

```bash
# #N 自動 link 候補の検出
gh pr view <N> --json body,comments -q '.body, (.comments[].body)' \
  | rg -n '(^|[^a-zA-Z0-9])#[0-9]+' && echo "AUTO-LINK CANDIDATES FOUND"

# @mention 候補
gh pr view <N> --json body,comments -q '.body, (.comments[].body)' \
  | rg -n '(^|[^a-zA-Z0-9])@[a-zA-Z0-9_-]+' && echo "MENTION CANDIDATES FOUND"
```

検出されたら `gh api -X PATCH /repos/<owner>/<repo>/issues/comments/<id> --input -` 等で書き直す。

## HEREDOC でメッセージ・PR 本文を渡すときの注意

`gh pr create --body "$(cat <<'EOF' ... EOF)"` や `git commit -m "$(cat <<'EOF' ... EOF)"` のように **シングルクオート付きヒアドキュメント (`<<'EOF'`)** で複数行を渡すとき、本文中の特殊文字を **絶対にエスケープしない**。

- `<<'EOF'` は変数展開もコマンド置換も**一切しない**ため、`\`・`$`・`` ` ``・`"` のエスケープは不要
- 過剰にエスケープすると `\` がリテラルで残り、レンダリング先 (GitHub Markdown / Slack 等) でコードブロックや変数が壊れる

### 具体例

```bash
# ❌ 誤: \` を入れると PR 本文に「\`\`\`」がそのまま残る
gh pr create --body "$(cat <<'EOF'
## Diagram

\`\`\`
A -> B
\`\`\`
EOF
)"

# ✅ 正: シングルクオート HEREDOC ではバッククォートをそのまま書く
gh pr create --body "$(cat <<'EOF'
## Diagram

```
A -> B
```
EOF
)"
```

### 確認手順

PR / commit 作成直後に必ず:

```bash
gh pr view <N> --json body -q .body | rg -n '\\`|\\\$' && echo "ESCAPED LITERALS REMAINING"
git log -1 --pretty=%B | rg -n '\\`|\\\$' && echo "ESCAPED LITERALS REMAINING"
```

`ESCAPED LITERALS REMAINING` が出たら `gh pr edit` / `git commit --amend` で書き直す。

### `<<EOF` (クオートなし) を使う場合だけ別

`<<EOF` (クオートなし) のヒアドキュメントは変数展開・コマンド置換が走るため、`$` `` ` `` `\` のリテラル展開が必要なら `\` でエスケープが必要。
基本的には `<<'EOF'` を使えば事故らないので、メッセージ・本文は常にシングルクオート HEREDOC を選ぶ。
