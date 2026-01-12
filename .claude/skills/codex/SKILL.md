---
name: codex
description: |
  OpenAI Codex CLIでタスクを実行し、Claude以外の視点を得る。
  コードレビュー、設計分析、実装提案でセカンドオピニオンが欲しいときに使用。
  Use for: "codexで見て", "別の視点で", "Codexにレビューさせて", "OpenAIの意見"
context: fork
agent: codex
user-invocable: true
---

# Codex Task Executor

Codex agentを使用してタスクを実行し、結果を返す。

## Usage

```
/codex <task>
/codex review src/auth/
/codex このアーキテクチャを分析して
```

## Behavior

1. ユーザーのタスクをcodex agentに委譲
2. codex execで実行、結果を取得
3. 結果をユーザーに提示

## Notes

- デフォルトは read-only（分析モード）
- 編集が必要な場合は明示的に指示すること
- 作業ディレクトリは現在のプロジェクトを使用
