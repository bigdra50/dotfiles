---
name: dual-review
description: |
  ClaudeとCodex/Copilotの両方でコードレビューし、総合的な結果を報告。2つ以上のAI視点で見落とし防止。
  --tool codex|copilot で外部ツールを選択可能（デフォルト: copilot）。
  Use for: "両方でレビュー", "総合レビュー", "デュアルレビュー", "ClaudeとCodexで見て", "ClaudeとCopilotで見て"
allowed-tools: Skill, Read
user-invocable: true
---

# Dual AI Review (Claude + Codex/Copilot)

ClaudeとCodex/Copilotの両方でレビューし、結果を統合して報告。

## Usage

```
/dual-review <target>                        # デフォルト: Claude + Copilot
/dual-review --tool codex src/               # Claude + Codex
/dual-review --tool copilot src/             # Claude + Copilot (明示)
/dual-review --tool copilot --models diverse src/  # Copilot をマルチモデルで
```

## Argument Parsing

1. `--tool codex|copilot` を抽出（デフォルト: copilot）
2. `--models` がある場合は Copilot 用に引き継ぐ（Codex 選択時は無視）
3. 残りをターゲットパスとして使用

## Workflow

1. **Phase 1: Claude Review**
   - Skill tool で `/claude-review <target>` を実行
   - 4観点（Security, Performance, Maintainability, Architecture）で分析
   - 結果を記録

2. **Phase 2: Codex/Copilot Review**
   - `--tool codex` の場合: `/codex-review <target>` を実行
   - `--tool copilot` の場合: `/copilot-review <target>` を実行（`--models` 引き継ぎ）
   - 同じ4観点で別AI視点から分析
   - 結果を記録

3. **Phase 3: 統合レポート**
   - 両方の結果をマージ
   - 重複を統合、差分をハイライト
   - 優先度順にソート

## Execution

```
# Phase 1
Skill(skill="claude-review", args="<target>")

# Phase 2 (Copilot の場合)
Skill(skill="copilot-review", args="<target> --models <models>")

# Phase 2 (Codex の場合)
Skill(skill="codex-review", args="<target>")

# Phase 3
統合レポート生成
```

## Output Format

```markdown
# Dual AI Review: <target>
External tool: <Codex|Copilot (models: ...)>

## Executive Summary
| AI | Critical | High | Medium | Low |
|----|----------|------|--------|-----|
| Claude | X | X | X | X |
| Codex/Copilot | X | X | X | X |

## Consensus (両方が指摘)
最も信頼度の高い問題。両AIが同じ問題を検出。

| 優先度 | 問題 | 箇所 | 指摘元 |
|--------|------|------|--------|
| Critical | ... | `file:line` | Both |

## Claude Only
Claudeのみが検出した問題。深いコード理解による発見。

## Codex/Copilot Only
外部ツールのみが検出した問題。異なる視点からの発見。

## Recommended Actions (Top 10)
1. [Critical/Consensus] ...
2. [High/Both] ...
3. [High/Claude] ...
4. [High/External] ...
```

## Value

- **見落とし防止**: 2つ以上のAIで相互補完
- **信頼度向上**: 両方が指摘 = 高確度
- **多角的視点**: 異なるモデルの強みを活用
- **Copilot選択時**: マルチモデルで更に多様な視点

## Notes

- 時間: 約10-15分（両方のレビュー合計）
- 順次実行（並列不可、Skill toolの制約）
- 結果の重複は統合時にマージ
- Copilot + `--models diverse` で最大のモデル多様性を確保
