---
name: refactor-loop
description: |
  unilyze メトリクスで収束判定するリファクタリングループ。
  ワースト型を特定→リファクタリング実施→unilyze diffで改善/悪化を定量判定→目標達成まで繰り返す。
  Use for: "refactor-loop", "定量リファクタリング", "CodeHealth上げて", "メトリクス改善ループ", "品質改善ループ"
---

# Refactor Loop

unilyze メトリクスの CodeHealth スコアを収束条件として、リファクタリングを反復実行する。

## When NOT to use

- C# 以外のコードベース (unilyze は C# 専用)
- 機能追加・バグ修正の途中 (そちらを先に完了させる)
- リリース直前で破壊的変更を入れたくないとき
- 短期的に削除予定のコード (測定する意味がない)
- メトリクス取れる規模に達していない新規プロジェクト
- レビュー観点での品質改善が主目的 → `/review-loop` または `/copilot-review-loop`

## Pitfalls (read first)

| Symptom | Cause | Fix |
|---|---|---|
| partial class や static 拡張が GodClass 判定される | 計測特性によるもの | `quality-audit/references/blind-spots.md` を参照、対象から除外 |
| `unilyze hotspot` が失敗 | 非 git リポジトリ or git 履歴が不足 | CodeHealth 順にフォールバック (本文 Step 1 に記載) |
| Degraded > 0 のまま次ラウンドへ進む | 悪化対応をスキップ | Step 4 の判定ロジックを厳守、悪化を直してから次へ |
| ベースラインが古い | snapshot 更新を忘れる | Step 7 で `cp refactor-after.json quality-audit.json` を必ず実行 |
| `--target 8.0` で永遠に収束しない | 既存コードベースの現実値に対し target 高すぎ | `unilyze metrics` で閾値を確認、target を 6.5〜7.5 に調整 |
| テスト失敗が次ラウンドにキャリーオーバーする | Step 3 のテスト実行前に Step 4 へ進んでいる | 順序厳守。テスト緑化を必須条件にする |

## Quick Reference

```bash
unilyze metrics   # メトリクス定義、CodeSmell 閾値一覧
unilyze schema    # JSON 出力の全フィールドリファレンス
```

## Usage

```
/refactor-loop [path] [--target <score>] [--max-rounds N]
```

- `path`: プロジェクトルート (省略時: カレントディレクトリ)
- `--target`: 目標 CodeHealth (省略時: 8.0)
- `--max-rounds`: 最大ラウンド数 (省略時: 5)

## Workflow

```python
snapshot = get_or_create_baseline(path)
hotspots = unilyze_hotspot(path)    # git 履歴があれば churn x complexity で優先順位付け
targets = identify_worst_types(snapshot, hotspots, threshold=target)
# hotspots が取得できない場合 (非 git / 履歴不足) は CodeHealth 順にフォールバック

for round in range(1, max_rounds + 1):
    type_to_fix = pick_worst(targets)
    refactor(type_to_fix)           # コード修正
    run_tests()                     # テスト通過を確認
    diff = unilyze_diff(snapshot)   # 定量比較
    report_round(round, diff)

    if all_above_target(diff):
        break
    if has_degradation(diff):
        fix_degradation()           # 悪化を修正してから次へ

    snapshot = update_snapshot()

print_final_summary()
```

### Step 1: ベースライン取得 & hotspot 分析

スナップショットはリポジトリルートの `.unilyze/` に保存する。

```bash
UNILYZE_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)/.unilyze"
mkdir -p "$UNILYZE_DIR"

# /quality-audit で作成済みなら再利用
if [ -f "$UNILYZE_DIR/quality-audit.json" ]; then
  cp "$UNILYZE_DIR/quality-audit.json" "$UNILYZE_DIR/refactor-before.json"
else
  # --prefix または -a で自前コードに絞る (サードパーティ除外)
  unilyze -p <path> --prefix "App." -f json -o "$UNILYZE_DIR/refactor-before.json"
fi
```

hotspot を取得して優先順位を決定する (ループ開始時に1回だけ実行)。
git 履歴が十分にある場合のみ有効。非 git リポジトリや作りたてのリポジトリではスキップし、CodeHealth 順で進める。

```bash
# git 履歴があれば hotspot を取得 (失敗しても続行)
unilyze hotspot -p <path> 2>&1 || echo "hotspot unavailable, using CodeHealth order"
```

hotspot が取得できた場合、「変更頻度が高い かつ CodeHealth が低い」型を優先的にリファクタリング対象とする。
CodeHealth だけで順位付けすると、滅多に変更しないコードに労力を使ってしまう。

ワースト型を抽出:

```bash
jq --argjson t 8.0 '[.typeMetrics[] | select(.codeHealth != null and .codeHealth < $t)] | sort_by(.codeHealth) | .[0]' "$UNILYZE_DIR/refactor-before.json"
```

partial class や static 拡張メソッドクラスが GodClass 判定されている場合、
計測特性によるものであり改善対象から除外してよい (詳細: quality-audit/references/blind-spots.md)。

### Step 2: リファクタリング実施

ワースト型のソースを読み、CodeSmell と メトリクスに基づいてリファクタリングする。

改善戦略の選択基準:

| CodeSmell / Metric | Strategy |
|---|---|
| GodClass (lines > 500) | 責務ごとにクラス分割 |
| LongMethod (lines > 60) | メソッド抽出 |
| HighComplexity (CogCC > 25) | 条件分岐の整理、早期 return、ストラテジーパターン |
| DeepNesting (depth > 4) | ガード節、メソッド抽出 |
| HighCoupling (CBO > 14) | インターフェース導入、依存逆転 |
| ExcessiveParameters (> 5) | パラメータオブジェクト導入 |
| LowCohesion (LCOM > 0.8) | 関連メソッド+フィールドを別クラスへ |
| BoxingAllocation | struct に override (ToString, GetHashCode)、ジェネリック制約、Span 活用 |
| ClosureCapture | static ラムダ化、ローカル変数をパラメータ渡し、closureless overload |
| ParamsArrayAllocation | 配列を事前作成して渡す、Span-based overload |
| CatchAllException | 具象例外型で catch、必要なら rethrow |
| MissingInnerException | `throw new X("msg", e)` で inner exception を渡す |
| ThrowingSystemException | ArgumentNullException 等の具象例外に変更 |

1つのラウンドで1つの型に集中する。複数の型を同時に変更しない。

Goodhart's Law に注意: メトリクス値を下げるためだけの変更（関数の過度な分割、boxing回避のために可読性を犠牲にする等）は行わない。変更後に「全体の可読性・保守性が改善したか」を定性的にも確認する。

CycCC が高い箇所はテスタビリティの問題。CogCC が高い箇所は可読性の問題。改善戦略が異なるので区別する。

### Step 3: テスト実行

リファクタリング後、テストを実行して既存動作を壊していないことを確認する。

```bash
dotnet test  # or project-specific test command
```

テストが失敗した場合、修正してからStep 4へ進む。

### Step 4: 定量比較

```bash
unilyze -p <path> -f json -o "$UNILYZE_DIR/refactor-after.json"
unilyze diff "$UNILYZE_DIR/refactor-before.json" "$UNILYZE_DIR/refactor-after.json" 2>&1
```

判定ロジック:
- Degraded = 0 かつ対象型の CodeHealth >= target → 成功、次の型へ
- Degraded = 0 かつ CodeHealth < target → 改善不十分、同じ型で続行
- Degraded > 0 → 悪化を修正してから再計測

### Step 5: ラウンドレポート

```
## Round N

| Type | Before | After | Delta |
|------|--------|-------|-------|
| Namespace.TypeName | 5.2 | 7.8 | +2.6 |

Changes: {変更内容の要約}
Status: Improved / Degraded / Insufficient
```

### Step 6: 収束判定

以下のいずれかで終了:
- 全対象型が目標 CodeHealth に到達
- 最大ラウンド数に到達
- ユーザーが終了を指示

### Step 7: 最終サマリー

```
## Refactor Loop Summary

| Round | Target Type | Before | After | Status |
|-------|-------------|--------|-------|--------|
| 1 | TypeAnalyzer | 5.2 | 7.8 | Improved |
| 2 | CodeSmellDetector | 6.1 | 8.5 | Target reached |
| 3 | DiffCalculator | 6.5 | 8.2 | Target reached |

Overall: N types improved, M reached target, K remaining
```

スナップショットを更新:
```bash
cp "$UNILYZE_DIR/refactor-after.json" "$UNILYZE_DIR/quality-audit.json"
```

## Anti-patterns

| 合理化 | 実像 |
|---|---|
| 「メトリクス値を下げるためなら多少可読性を犠牲にしてよい」 | Goodhart's Law。指標が target になった瞬間に良い指標ではなくなる |
| 「1 ラウンドで複数型をまとめて改善した方が効率的」 | 悪化原因の切り分けが不可能になる。1 型ずつ守る |
| 「partial class を分割して GodClass 解消」 | 計測の都合に実装を合わせる本末転倒。除外で対処する |
| 「CodeHealth 7.99 → 8.00 まで詰める」 | 小数点以下は誤差レベル。target に到達したら止める |
| 「hotspot 取れないから CodeHealth 順だけで進める」 | 滅多に変更しないコードに労力を使ってしまう。せめて頻出ファイルを目視確認 |
| 「テスト書いていないが mechanical な変更だから安全」 | 振る舞いが変わる refactor は珍しくない。テストなしなら範囲を最小化する |

## Related skills

- `/quality-audit` — メトリクス + AI レビューの統合監査 (refactor の前段で baseline 取得)
- `/csharp-diagnose` — ReSharper + similarity-csharp による事前診断 (refactor 候補の発見)
- `/csharp-perf-optimizer` — Cysharp 知見によるパフォーマンス最適化 (perf 改善が主目的なら)
- `/review-loop` — refactor 結果を Codex レビューでさらに磨く
- `/plan-loop` — 大規模 refactor の計画段階を Codex でレビュー
- `empirical-prompt-tuning` (mizchi) — このスキル自体の品質を bias-free に評価

## Notes

- 1ラウンド1型に集中し、変更のスコープを限定する
- テスト通過を必ず確認してから次のラウンドへ
- `/quality-audit` のスナップショットをベースラインとして再利用可能
- 悪化が発生した場合は次のラウンドに進まず、まず悪化を修正する
- hotspot はループ開始時に1回取得すれば十分。git churn はループ中に大きく変わらない
- hotspot は git 履歴が必要。非 git リポジトリや履歴が少ない場合は CodeHealth 順にフォールバックする
