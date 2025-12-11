---
allowed-tools: [Bash, Read, Grep, TodoWrite, AskUserQuestion]
argument-hint: [branch-name]
description: Create new git branch and worktree simultaneously for parallel work environments
model: sonnet
---

# create-worktree

新しいGitブランチとWorktreeを同時に作成し、独立した作業環境を構築します。複数ブランチを並行して作業する際に便利です。

## ワークフロー:

1. **Worktreeパス決定**
   - プロジェクトメモリーからWorktree設定を検索
   - CLAUDE.mdやCLAUDE.local.mdから設定を確認
   - 見つからない場合はユーザーに確認
   - デフォルト: `../worktrees/[プロジェクト名]/`

2. **入力解析**
   - ブランチ名の形式確認（feature/, fix/, refactor/, hotfix/）
   - Worktreeディレクトリ名の自動生成（プレフィックス除去）
   - 命名規則の適用

3. **現在の状態確認**
   - 現在のブランチとWorktreeリストを表示
   - 重複チェック（同名ブランチ/Worktreeの確認）
   - 既存Worktreeとの競合確認

4. **Worktree作成**
   - `git worktree add -b` でブランチとWorktreeを同時作成
   - 決定されたパスにWorktreeを配置
   - 進捗状況の表示

5. **作成後の検証**
   - Worktree作成成功の確認
   - 作成されたパスの表示
   - オプションで新しいWorktreeへの移動提案

## パス決定ロジック:

1. **メモリーチェック** (優先度: 高)
   - プロジェクト固有メモリーファイルを確認
   - Worktree運用方針やパス設定を検索

2. **プロジェクト設定チェック** (優先度: 中)
   - CLAUDE.md, CLAUDE.local.mdを確認
   - worktree関連の設定を抽出

3. **ユーザー確認** (優先度: 低)
   - 上記で見つからない場合は対話的に確認
   - 推奨パス: `../worktrees/[プロジェクト名]/`
   - カスタムパスの指定も可能

## 実行例:

```bash
# 機能開発用Worktree作成
claude /create-worktree feature/new-feature
# → 設定に基づいてWorktreeパスを決定し作成

# バグ修正用Worktree作成
claude /create-worktree fix/critical-bug
# → プレフィックスを除去してdirectory名を自動生成

# ホットフィックス用Worktree作成
claude /create-worktree hotfix/security-patch
# → 緊急修正用のWorktreeを作成

# 対話モードで作成（引数なし）
claude /create-worktree
# → ブランチ名とパスを対話的に決定
```

## 作成後の操作:

### Worktreeへ移動
```bash
cd [作成されたWorktreeパス]
```

### Worktreeリスト確認
```bash
git worktree list
```

### Worktree削除（作業完了後）
```bash
# メインディレクトリに戻ってから実行
git worktree remove [Worktreeパス]
```

## エラーハンドリング:

- **Gitリポジトリでない場合**: エラーメッセージを表示して終了
- **ブランチ名が既に存在する場合**: 既存ブランチの確認と対処法を提示
- **Worktreeディレクトリが既に存在する場合**: 既存Worktreeの確認を促す
- **ディスク容量不足**: 大規模プロジェクトでの容量チェック
- **無効なブランチ名**: Git命名規則違反の検出と修正提案
- **パス設定が見つからない場合**: ユーザーに対話的に確認

## プロジェクトタイプ別の考慮事項:

### Unityプロジェクト
- 各WorktreeはLibrary/フォルダを独自に持つ
- 初回起動時はインポート処理が必要（数分かかる可能性）
- 複数Worktreeで同時にエディタを開くことが可能

### Node.jsプロジェクト
- node_modules/の再インストールが必要
- package-lock.jsonの競合に注意
- 各Worktreeでnpm installの実行推奨

### 大規模プロジェクト
- ディスク容量を事前確認
- 初回セットアップに時間がかかる可能性
- キャッシュファイルの重複に注意

## 使用上の注意:

- Worktreeごとに独立した作業環境として動作
- ビルド成果物やキャッシュは各Worktreeで独立
- .gitignoreされたファイルは共有されない

## 引数:
- `[ブランチ名]`: 作成するブランチ名（例: feature/new-feature）

$ARGUMENTSが提供された場合はそれをブランチ名として使用します。提供されない場合は対話形式でブランチ名を確認します。