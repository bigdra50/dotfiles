---
name: claude-stats
description: Claude Code のツール使用統計を集計・表示する。/claude-stats で呼び出し、期間指定やツール別/Skill別/セッション別の集計が可能。
allowed-tools: Bash, Read
user-invocable: true
---

# Claude Code Usage Statistics

ツール使用ログ (`~/.claude/logs/tool-usage.jsonl`) から統計を集計して表示する。

## Usage

```
/claude-stats [period] [type]
```

### Parameters

**period** (default: all)
- `today` - 今日の統計
- `week` - 過去7日間
- `month` - 過去30日間
- `all` - 全期間

**type** (default: summary)
- `summary` - 全体サマリー (ツール、Skill、サブエージェント、MCP)
- `tools` - ツール別
- `skills` - Skill別
- `subagents` - Task サブエージェント別
- `sessions` - セッション別
- `files` - ファイルアクセス別
- `mcp` - MCPサーバー別

### Examples

```
/claude-stats              # 全期間のサマリー
/claude-stats today        # 今日のサマリー
/claude-stats week tools   # 過去7日間のツール別
/claude-stats month skills # 過去30日間のSkill別
```

## Workflow

1. 引数をパースして period と type を決定
2. 集計スクリプトを実行
3. 結果をユーザーに表示

Execute:

```bash
python3 ~/.claude/skills/skill-creator/claude-stats/scripts/aggregate.py --period {period} --type {type}
```
