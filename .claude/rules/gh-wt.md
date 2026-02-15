# gh-wt (Git Worktree管理)

`gh wt` はgit worktreeをfzf連携で操作するGitHub CLI拡張。

## コマンド

| コマンド | 用途 |
|---------|------|
| `gh wt list` | worktree一覧表示 |
| `gh wt add <branch> [path]` | worktree作成（依存キャッシュ自動リンク） |
| `gh wt remove` | worktree削除（fzf選択） |
| `gh wt <command>` | 選択したworktreeのパスを引数として渡す |
| `gh wt -- <command>` | 選択したworktree内でコマンド実行 |
| `gh wt --` | 選択したworktreeでシェルを開く |

## 使い分け

- `gh wt code` — worktreeパスを引数として渡す（VSCode等で開く）
- `gh wt -- npm test` — worktreeディレクトリ内でコマンド実行

## 依存キャッシュ

worktree作成時、親リポジトリの依存ディレクトリを自動リンク。対応: `node_modules`, `.venv`, `target`, `vendor`, `.build` 等。

## Claude Codeでの活用

並行作業やブランチ切り替えなしの検証にworktreeを使う。

```bash
# 機能ブランチ用worktree作成
gh wt add feature-xyz

# worktree内でテスト実行
gh wt -- npm test

# worktree内でClaude Codeセッション開始
gh wt -- claude
```
