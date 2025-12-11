---
allowed-tools: [Read, Edit, Write, Bash, Grep, Glob, TodoWrite]
argument-hint: [project-name] [update-content]
description: Update project information manually or automatically from daily reports
model: sonnet
---

# プロジェクト情報を更新する

指定されたプロジェクトの情報を更新します。

## 使用方法
- `/prj-update [プロジェクト名] [更新内容]` - 手動でプロジェクト情報を更新
- `/prj-update` - 引数なしの場合、今日の日報から自動的にプロジェクト情報を更新

## 実行内容:

### 引数ありの場合（手動更新）
1. **プロジェクトファイルの特定**
   - ~/Documents/Obsidian\ Vault/projects/[プロジェクト名]/ ディレクトリを確認
   - 存在しない場合は新規プロジェクトとして作成

2. **更新内容の分析と適用**
   - タスクの追加・更新・完了マーク
   - 進捗状況の更新
   - 作業ログの追記
   - 優先度や期限の変更

3. **関連ファイルの更新**
   - projects/dashboard.md のプロジェクト概要を更新
   - projects/current-tasks.md の該当タスクを更新
   - 必要に応じて priorities.md も更新

### 引数なしの場合（自動更新）
1. **今日の日報から情報抽出**
   - ~/Documents/Obsidian\ Vault/daily/$(date +%Y-%m-%d\(%a\)).md を読み取り
   - ハッシュタグ（#unione、#表参道未来都市等）でプロジェクト分類
   - 作業ログセクションから時系列で作業内容を抽出

2. **プロジェクト別情報の整理**
   - **会議内容**: 「会議」「MTG」「打ち合わせ」を含む記録
   - **進捗更新**: 「完了」「進捗」「達成」を含む記録
   - **課題・ブロッカー**: 「課題」「問題」「エラー」を含む記録
   - **次回アクション**: 「明日」「来週」「次回」を含む記録

3. **自動分類と更新**
   - 各プロジェクトの ~/Documents/Obsidian\ Vault/projects/[project-name]/log.md に作業ログを追記
   - 進捗情報は dashboard.md に反映
   - 課題やアクションアイテムは current-tasks.md に反映
   - 更新日時を自動記録

4. **更新結果の報告**
   - 抽出された情報の内容確認
   - 各プロジェクトファイルの更新状況を表示
   - 手動で追加確認が必要な項目があれば提案

## 更新内容の書式例:
- "タスク追加: 新機能の実装 期限:2025-07-15"
- "完了: バグ修正 #123"
- "進捗: 開発 80%完了"
- "優先度: 高に変更"
- "作業ログ: APIの実装が完了、テスト開始"

## 自動処理:
- ハッシュタグ（#プロジェクト名）を自動付与
- 更新日時を自動記録
- 関連するタスクの依存関係を確認

## 連携コマンド:
- `/times` で記録した分報スタイルの作業ログを自動収集
- `/nippo-finalize` での日報完成時にも自動更新を実行