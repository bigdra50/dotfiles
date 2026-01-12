---
name: claude-stats
description: Claude Code のツール使用統計を集計・表示する。/claude-stats で呼び出し、期間指定やツール別/Skill別/セッション別の集計が可能。
allowed-tools: Bash
user-invocable: true
---

# Claude Code Usage Statistics

`~/.claude/projects/` 配下の transcript JSONL から統計を集計して表示する。

## Usage

```
/claude-stats [period] [type]
```

**period**: `today` | `week` | `month` | `all` (default)

**type**: `summary` (default) | `tools` | `skills` | `subagents` | `sessions` | `files` | `mcp`

## Examples

```
/claude-stats              # 全期間サマリー
/claude-stats today tools  # 今日のツール別
/claude-stats week skills  # 過去7日間のSkill別
```

## Execution

引数をパースし、以下を実行:

```bash
python3 scripts/aggregate.py --period {period} --type {type}
```
