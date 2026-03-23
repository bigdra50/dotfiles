---
name: copilot
description: |
  GitHub Copilot CLIでタスクを実行し、Claude以外の視点を得る。
  コードレビュー、設計分析、実装提案でセカンドオピニオンが欲しいときに使用。
  --model でモデル指定可能（デフォルト: gpt-5.4）。
  Use for: "copilotで見て", "別の視点で", "Copilotにレビューさせて", "GitHub Copilotの意見"
context: fork
agent: copilot
user-invocable: true
---

# Copilot Task Executor

Copilot agentを使用してタスクを実行し、結果を返す。

## Usage

```
/copilot <task>
/copilot review src/auth/
/copilot --model gpt-5 このアーキテクチャを分析して
/copilot --model claude-opus-4.6 セキュリティレビュー
/copilot --effort high 複雑なバグを分析して
```

## Argument Parsing

引数から `--model <model>` と `--effort <level>` を抽出し、残りをタスクとして渡す。

- `--model` が指定された場合: copilot agent に `--model <model>` 付きで実行を指示
- `--model` が省略された場合: ローカル設定のデフォルトを使用
- `--effort` が指定された場合: copilot agent に `--effort <level>` 付きで実行を指示
- `--effort` が省略された場合: ローカル設定に従う

## Behavior

1. 引数を解析（`--model`, `--effort` の有無を確認）
2. ユーザーのタスクをcopilot agentに委譲
3. copilot -p で実行、結果を取得
4. 結果をユーザーに提示

## Notes

- デフォルトは `--no-ask-user`（分析モード）
- 編集が必要な場合は明示的に指示すること
- 作業ディレクトリは現在のプロジェクトを使用
- モデル例: gpt-5, claude-opus-4.6, claude-sonnet-4.6, gemini-3.1-pro, gpt-5.4-mini
