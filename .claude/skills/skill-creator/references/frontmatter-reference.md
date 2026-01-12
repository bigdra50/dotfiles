# Frontmatter Reference

## Required Fields

| Field | Description | Constraints |
|-------|-------------|-------------|
| `name` | Skill identifier | 64 chars max, lowercase/numbers/hyphens only, no "anthropic"/"claude" |
| `description` | What the skill does and when to use it | 1024 chars max, include trigger terms |

## Optional Fields

| Field | Description | Values |
|-------|-------------|--------|
| `allowed-tools` | Restrict available tools | Comma-separated or YAML list |
| `model` | Execution model | `claude-sonnet-4-20250514`, `claude-opus-4-5-20251101`, etc. |
| `context` | Execution context | `fork` for isolated subagent |
| `agent` | Subagent type | `Explore`, `Plan`, `general-purpose`, custom name |
| `hooks` | Lifecycle hooks | PreToolUse, PostToolUse, Stop events |
| `user-invocable` | Show in slash menu | `true` (default) / `false` |
| `disable-model-invocation` | Block Skill tool invocation | `true` / `false` (default) |

## allowed-tools Examples

```yaml
# Comma-separated
allowed-tools: Read, Grep, Glob

# YAML list
allowed-tools:
  - Read
  - Grep
  - Bash(git add:*)
  - Bash(python:*)
```

## context: fork

Run skill in isolated subagent with separate context:

```yaml
context: fork
agent: Explore
```

## hooks Example

```yaml
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate.sh $TOOL_INPUT"
          once: true
```

## Visibility Matrix

| Settings | Slash Menu | Skill Tool | Auto-discovery |
|----------|-----------|------------|----------------|
| Default | Yes | Yes | Yes |
| `user-invocable: false` | No | Yes | Yes |
| `disable-model-invocation: true` | Yes | No | Yes |

## Complete Example

```yaml
---
name: code-analyzer
description: Analyze code quality and generate reports. Use when reviewing code, checking patterns, or generating documentation from source files.
allowed-tools: Read, Grep, Glob, Bash(python:*)
model: claude-sonnet-4-20250514
context: fork
agent: Explore
user-invocable: true
---
```
