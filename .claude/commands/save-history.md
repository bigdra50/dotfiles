---
description: 会話履歴をHISTORY-REPOリポジトリに保存
allowed-tools: Bash(git remote get-url origin *), Bash(ghq root), Bash(git branch --show-current), Bash(mkdir -p *), Bash(ls *), Write
---

この会話の履歴をHISTORY-REPOリポジトリに保存してください。

追加メモ: $ARGUMENTS

## 手順

### 1. リポジトリ情報の取得

現在の作業ディレクトリで以下を実行してリモートURLを取得:

```bash
git remote get-url origin 2>/dev/null
```

- URLから `github.com/<user>/<repo>` パスを抽出（`.git`サフィックス除去、`https://`やSSH形式も対応）
  - 例: `https://github.com/foo/bar.git` → `github.com/foo/bar`
  - 例: `git@github.com:foo/bar.git` → `github.com/foo/bar`
  - `github.com/` プレフィックスを必ず含めること
- gitリポジトリ外、またはリモートが無い場合は `other` を使用

### 2. 保存先の決定

```bash
HISTORY_REPO="$(ghq root)/github.com/ORG/HISTORY-REPO"
```

保存先: `$HISTORY_REPO/<抽出したパス>/`

ディレクトリが無ければ `mkdir -p` で作成。

### 3. ファイル名の決定

- 会話内容を簡潔に表す名前（日本語可、スペースはハイフンに置換）
- 拡張子 `.md`
- 同名ファイルが既に存在する場合は末尾に `-2`, `-3` と連番を付与

### 4. Markdownファイルの作成

以下の形式で作成:

```
# <タイトル>

- 日時: YYYY-MM-DD HH:MM
- リポジトリ: <user>/<repo>（またはgitリポジトリ外）
- ブランチ: <branch名>

## 要約

<会話で行った作業の概要を3-5行で記述>

## 会話履歴

<会話の全やりとりを時系列で記録する。
各ターンを「### 🧑 User」「### 🤖 Assistant」で区切り、
コード変更・コマンド実行・決定事項を漏れなく含める。
コードブロックは元の言語指定を維持する。>
```

### 5. 保存と報告

Writeツールでファイルを保存し、保存先パスを表示する。
