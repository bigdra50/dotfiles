---
name: copilot-review-loop
description: |
  実装コードをCopilot CLIマルチモデルレビューで反復改善するループ。/copilot-review実行→FB分類→コード修正→再レビューを収束まで繰り返す。
  --models で観点別モデル、--effort で推論レベルを指定可能。
  Use for: "copilot-review-loop", "Copilotで品質上げて", "マルチモデルレビューループ", "反復コードレビュー(Copilot)"
user-invocable: true
---

# Code Review Loop (Copilot)

実装済みコードに /copilot-review を実行し、指摘を反映して再レビューする反復ループ。

## When NOT to use

- 単発レビューで十分なとき → `/copilot-review` (loop なし)
- 設計プランのレビュー対象 → `/copilot-plan-loop`
- Codex CLI を使いたい → `/review-loop`
- メトリクス駆動の構造改善 → `/refactor-loop`
- まだコードを書いていない → 通常会話で実装してから

## Pitfalls (read first)

| Symptom | Cause | Fix |
|---|---|---|
| `--models all-gpt` で 1 モデルしか動かない | argparse で models 配列が agent に伝わっていない | Step 2 で `--models` をそのまま渡しているか確認 |
| 観点ごとに別モデルを指定したい | デフォルト mapping が固定 | `--models security=gpt-5,perf=claude-opus-4.6` のように観点指定 |
| 同じ指摘が毎ラウンド出る | 修正履歴が次ラウンドの reviewer に渡っていない | 修正内容を要約し、次の `/copilot-review` 引数に含める |
| 修正がテストを壊す | Step 4 のテスト実行をスキップしている | プロジェクトの test command を CLAUDE.md から特定し必ず実行 |
| `--effort high` でレートリミット | 4 観点 × 高 effort はコスト大 | observability 不足箇所だけ effort high に絞る |

## Usage

```
/copilot-review-loop                                    # 直近の変更を対象にループ開始
/copilot-review-loop src/relay/                         # 指定パスを対象
/copilot-review-loop --staged                           # git staged の変更を対象
/copilot-review-loop --models all-gpt src/              # 全観点GPT
/copilot-review-loop --effort high src/                 # 高推論レベル
```

## Workflow

```python
target = resolve_target(args or recent_changes)
models_arg = parse_models_arg(args)
effort_arg = parse_effort_arg(args)
round = 0
history = []

while True:
    round += 1
    review = copilot_review(target, models_arg, effort_arg)  # /copilot-review を実行
    must, should, nice = classify(review)
    report_to_user(round, must, should, nice)

    if not must and not should:
        break
    if user_wants_to_stop():
        break

    approved = ask_user_which_to_address(must + should)
    apply_fixes(target, approved)            # コードを修正
    run_tests_if_available()                 # テスト実行で壊れていないか確認
    history.append((review, approved))

print_summary(history)
```

## Step 1: 対象特定

レビュー対象を決定する:

- 引数にパスがあればそのパス
- `--staged` なら `git diff --staged` の変更ファイル
- なければ会話コンテキストから直近の変更ファイルを特定
- それでもなければユーザーに確認

## Step 2: /copilot-review 実行

Skill tool で `/copilot-review` を実行する。対象パスと `--models`, `--effort` 引数を渡す。

4観点（セキュリティ、パフォーマンス、保守性、設計）のマルチモデル並列レビュー結果が返る。

## Step 3: FB 分類

レビュー結果の各指摘を重大度で再分類:

- [MUST] バグ、セキュリティ脆弱性、データ損失リスク
- [SHOULD] パフォーマンス改善、設計改善、可読性向上
- [NICE] スタイル、命名の好み、ドキュメント追加

```
Round N レビュー結果:
  MUST:   X件 — {一覧}
  SHOULD: X件 — {一覧}
  NICE:   X件 — {一覧}
```

ユーザーに報告し、対応方針を確認する。

## Step 4: コード修正

ユーザーの承認を得た MUST + SHOULD 項目に対してコードを修正する。

修正後、テストがあれば実行して既存の動作を壊していないか確認する。
テスト実行コマンドはプロジェクトの CLAUDE.md や設定から判断する。

## Step 5: 収束判定

以下のいずれかで終了:
- MUST と SHOULD が両方 0 件
- ユーザーが終了を指示

終了時、全ラウンドのサマリーを報告:

```
## Code Review Summary (Copilot Multi-Model)

| Round | MUST | SHOULD | NICE | 修正ファイル数 |
|-------|------|--------|------|----------------|
| 1     | 2    | 4      | 3    | 5              |
| 2     | 1    | 2      | 1    | 3              |
| 3     | 0    | 0      | 1    | 0              |

対応済み: X件 / 未対応 (NICE): X件
```

## Anti-patterns

| 合理化 | 実像 |
|---|---|
| 「マルチモデルだから観点間で矛盾しない」 | 観点ごとに別モデルなら矛盾し得る。ユーザー判断で優先順位を決める |
| 「`--models all-gpt` で十分 (Claude 不要)」 | モデルファミリーで盲点が偏る。混合の方が見落としが減る |
| 「テスト失敗したけどレビュー結果は反映済みだから次へ」 | 修正で別の不具合を導入。テスト緑化前に次ラウンドへ進まない |
| 「NICE は無視してよい (時間ない)」 | NICE が積もると debt 化。ユーザーに判断を委ねる方が良い |
| 「`/copilot-review` の出力をそのまま applied=true にしてよい」 | reviewer は提案するだけ。承認はユーザー、適用は別ステップ |

## Related skills

- `/copilot-plan-loop` — 設計プランを Copilot でループ (code ではなく plan 対象)
- `/review-loop` — 同じワークフローを Codex CLI で実施
- `/refactor-loop` — メトリクス駆動の構造改善ループ (CodeHealth 系、別系統)
- `/copilot-review` — このスキルが委譲する単発マルチモデルレビュー
- `/dual-review` — Claude + Copilot を統合した単発レビュー
- `empirical-prompt-tuning` (mizchi) — このスキル自体の品質を bias-free に評価

## Notes

- レビューは `/copilot-review` スキルに委譲する。直接 copilot -p を呼ばない
- `--models`, `--effort` 引数は `/copilot-review` にそのまま渡す
- 各ラウンドの修正内容を次ラウンドのレビューに反映し、同じ指摘の繰り返しを防ぐ
- コード修正はユーザー承認後に実行する。自動修正はしない
- NICE 項目は対応を強制しない。ユーザー判断に委ねる
