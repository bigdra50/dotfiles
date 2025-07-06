# 朝のスタンドアップセッション

ClaudeCodeとの対話形式で、スタンドアップミーティングを実施します。

## 実行内容:

1. **昨日の振り返り**
   - 前日の日報ファイル(~/Documents/Obsidian\ Vault/daily/$(date -v-1d +%Y-%m-%d\(%a\)).md)から作業内容を自動抽出
   - 完了したタスクと未完了タスクの確認
   - 想定との差異や課題の洗い出し

2. **今日の作業計画**
   - ~/Documents/Obsidian\ Vault/projects/current-tasks.md から今日予定のタスクを表示
   - ~/Documents/Obsidian\ Vault/projects/priorities.md から優先度に基づく作業順序の提案
   - 時間配分とリソース確認

3. **ブロッカーと課題の特定**
   - 進行を妨げる要因の確認
   - 依存関係のあるタスクの状況確認
   - サポートが必要な領域の特定

4. **今日の目標設定と記録**
   - 本日の日報ファイル(~/Documents/Obsidian\ Vault/daily/$(date +%Y-%m-%d\(%a\)).md)に結果を記録
   - 具体的で達成可能な目標の設定
   - 成功の定義と測定方法の明確化

## 対話形式の流れ:

### ステップ1: 昨日の振り返り
- 前日の日報から「📝 作業ログ」セクションを読み取り
- 完了・未完了タスクの整理
- ユーザーに振り返りコメントを求める

### ステップ2: 今日の計画確認
- current-tasks.mdから今日のタスクを抽出
- priorities.mdの優先度マトリックスを参照
- ユーザーに計画調整の確認

### ステップ3: ブロッカー確認
- 技術的課題、リソース不足、外部依存等を確認
- 各プロジェクトの~/Documents/Obsidian\ Vault/projects/[project-name]/tasks.mdも参照

### ステップ4: 目標設定と記録
- 今日の具体的な目標を設定
- 本日の日報に以下の形式で記録:

## 記録される内容:

本日の日報ファイル(~/Documents/Obsidian\ Vault/daily/$(date +%Y-%m-%d\(%a\)).md)に追記:

```markdown
$(date +%H:%M) - スタンドアップセッション完了

【昨日の実績振り返り】
- ✅ 完了: [タスク内容]
- ❌ 持ち越し: [タスク内容]
- 📝 学び: [気づいた点]

【今日の目標】
- 🎯 メイン: [具体的な成功条件]
- 📋 サブ: [具体的な成功条件]

【ブロッカー・注意点】
- ⚠️ [課題と対応方法]

【作業予定】
- 午前: [作業内容]
- 午後: [作業内容]
```

## 更新対象ファイル:

- 本日の日報ファイル: スタンドアップ結果を記録
- ~/Documents/Obsidian\ Vault/projects/current-tasks.md: 必要に応じて優先度調整
- ~/Documents/Obsidian\ Vault/projects/dashboard.md: ブロッカー情報を反映