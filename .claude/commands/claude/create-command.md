---
allowed-tools: Write,Edit,Read,Grep,TodoWrite,Task
description: Create a new slash command from natural language input with best practices
model: sonnet
---

# 新しいスラッシュコマンドをベストプラクティスに従って作成する

ベストプラクティスに準拠した高品質なスラッシュコマンドを自動生成します。

以下のリファレンス内容を前提とします｡

@../../docs/claude/slash-commands.md  
@../../docs/claude/settings.md

## ⚠️ 重要: コマンドの配置場所

**プロジェクト固有のコマンド**:

- プロジェクトのリポジトリ内 `.claude/commands/` に作成
- チームで共有され、プロジェクトと共にバージョン管理される
- 例: そのプロジェクト専用のワークフロー、ビルド手順、デプロイコマンド

**グローバル（個人用）コマンド**:

- ホームディレクトリ `~/.claude/commands/` に作成
- すべてのプロジェクトで利用可能な汎用コマンド
- 例: 一般的なGit操作、コードレビュー、ドキュメント生成

**判断基準**:

- プロジェクト固有の設定やツールを参照する → プロジェクトディレクトリ
- 汎用的で他のプロジェクトでも使える → グローバルディレクトリ

## コマンドファイル構成:

### 必須要素:

1. **YAMLフロントマター**（ファイル冒頭）:

   ```yaml
   ---
   allowed-tools: [必要なツール権限のリスト]
   description: [簡潔な英語説明]
   ---
   ```

2. **コマンド本体**:
   - タイトルと概要説明
   - ワークフロー定義（簡潔に）
   - エラーハンドリング
   - 使用方法（最小限の例）

### 利用可能なテンプレートタイプ:

- **基本**: 汎用コマンド用（allowed-tools: Read,Write,Edit）
- **Git操作**: Git関連（allowed-tools: Bash(git:\*),Read）
- **プロジェクト管理**: タスク管理（allowed-tools: Read,Write,TodoWrite）
- **ドキュメント生成**: 自動生成（allowed-tools: Read,Write,Grep）
- **オーケストレーター**: 複雑なワークフロー（allowed-tools: Task,TodoWrite）

### ベストプラクティス:

- 冗長な例は避け、簡潔な説明を心がける
- allowed-toolsは最小限の権限のみ指定
- descriptionは1行で機能を明確に説明

## ワークフロー:

1. **コマンド名選択**
   - コマンド名を生成（既存との重複チェック）

2. **メタデータ生成**
   - `allowed-tools`: 必要な権限を自動判定
   - `description`: 簡潔な英語説明

3. **コマンドファイル作成**
   - YAMLフロントマターとコマンド本体を生成
   - プレビュー表示して確認
   - 適切なディレクトリに保存（上記の配置場所の基準に従う）
