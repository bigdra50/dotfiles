---
name: copilot-review
description: |
  Copilot CLIを使ったマルチモデル多角的コードレビュー。セキュリティ、パフォーマンス、保守性、設計の4観点を異なるモデルで並列分析。
  --models で観点別モデルを指定可能。デフォルトはGPT最新モデル優先のマッピング。
  Use for: "copilotでレビュー", "マルチモデルレビュー", "Copilotに見てもらって", "別視点でレビュー"
allowed-tools: Bash, TaskOutput, Read
user-invocable: true
---

# Copilot Multi-Model Review

4つの観点を異なるモデルで並列実行し、統合レポートを生成。
単一モデルでは検出できない盲点をモデル多様性で補完する。

## Usage

```
/copilot-review <target>
/copilot-review src/auth/
/copilot-review --models gpt-5,claude-opus-4.6,gemini-3.1-pro,claude-sonnet-4.6 src/
/copilot-review --models all-free src/   # 全観点を無料モデル(GPT-4.1)で実行
```

## Model Mapping

### Default (GPT-5.4 メイン)

| 観点 | モデル | 理由 |
|------|--------|------|
| Security | gpt-5.4 | 最新GPT、論理推論・パターン認識 |
| Performance | gpt-5.4 | コード最適化・計算量分析 |
| Maintainability | gpt-5.4 | 構造分析・一貫性検出 |
| Architecture | claude-opus-4.6 | 深い設計判断、別視点の確保 |

デフォルトで 4 premium requests/回。3観点をGPT-5.4で統一しつつ、Architectureのみ Claude Opus で異なる視点を入れる。

### --models による上書き

カンマ区切りで4モデルを指定（順序: Security, Performance, Maintainability, Architecture）:

```
--models gpt-5,gpt-5,gemini-3.1-pro,claude-opus-4.6
```

プリセット:
- `--models all-gpt` → 全観点 gpt-5.4
- `--models diverse` → gpt-5.4, claude-opus-4.6, gpt-5.4, claude-sonnet-4.6
- `--models all-claude` → 全観点 claude-opus-4.6

## Argument Parsing

1. `--models <value>` を抽出
2. プリセット名なら展開、カンマ区切りなら分割
3. 残りの引数をターゲットパスとして使用

## Execution

Bash toolで4つの`copilot -p`を run_in_background: true で並列起動:

```bash
cd <target_dir> && copilot -p "[Security Review] ..." --model <security_model> --no-ask-user 2>/dev/null
cd <target_dir> && copilot -p "[Performance Review] ..." --model <perf_model> --no-ask-user 2>/dev/null
cd <target_dir> && copilot -p "[Maintainability Review] ..." --model <maint_model> --no-ask-user 2>/dev/null
cd <target_dir> && copilot -p "[Architecture Review] ..." --model <arch_model> --no-ask-user 2>/dev/null
```

## Review Prompts

**Security:**
```
[Security Review] このプロジェクトを以下の観点でレビュー:
- 機密情報の露出リスク（APIキー、認証情報等）
- 入力検証の不備
- 安全でないデータ処理
具体的な問題箇所と修正案を提示。
```

**Performance:**
```
[Performance Review] このプロジェクトを以下の観点でレビュー:
- 不要なループ、毎フレーム処理の最適化機会
- メモリリーク、リソース解放漏れ
- GC Alloc削減の機会
- 計算量・アルゴリズム効率
具体的な問題箇所と改善案を提示。
```

**Maintainability:**
```
[Maintainability Review] このプロジェクトを以下の観点でレビュー:
- コードの可読性、複雑度
- 重複コード、DRY原則違反
- 命名規則、一貫性
- コメント・ドキュメントの適切さ
具体的な問題箇所とリファクタリング案を提示。
```

**Architecture:**
```
[Architecture Review] このプロジェクトを以下の観点でレビュー:
- 設計パターンの適切な使用
- 責務分離、単一責任原則
- 依存関係、結合度
- 拡張性、テスト容易性
具体的な問題箇所と改善案を提示。
```

## Workflow

1. 引数解析（--models とターゲットパス）
2. 4つのBash toolを同時に起動
   - `run_in_background: true`
   - `timeout: 600000` (10分)
3. TaskOutputで全タスクの完了を待機
4. 結果を統合してレポート作成

## Output Format

```markdown
# Copilot Multi-Model Review: <target>

## Model Configuration
| 観点 | モデル |
|------|--------|
| Security | <model> |
| Performance | <model> |
| Maintainability | <model> |
| Architecture | <model> |

## Summary
| 優先度 | 件数 |
|--------|------|
| Critical/High | X件 |
| Medium | X件 |
| Low | X件 |

## Security (<model>)
[結果テーブル]

## Performance (<model>)
[結果テーブル]

## Maintainability (<model>)
[結果テーブル]

## Architecture (<model>)
[結果テーブル]

## Cross-Model Insights
異なるモデルが同じ問題を指摘した場合、信頼度が高い。

## Recommended Actions (Top 10)
1. [Critical] ...
2. [High] ...
```

## Notes

- 全て `--no-ask-user` で実行（変更なし）
- `2>/dev/null` でstderr（進捗ログ）を抑制
- 結果の重複があれば統合時にマージ
- 無料モデル (gpt-4.1, gpt-5-mini) を活用してコスト最適化
- Cross-Model Insights セクションで複数モデルの合意点を強調
