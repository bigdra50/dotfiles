# AI委譲ルール

各LLMの得意領域を活かして作業を分担する。

## モデル特性と役割

| 役割 | 委譲先 | モデル | 特性 |
| --- | --- | --- | --- |
| 高速な実装 | `cursor-agent` | Composer 2.5 | 高速。Opus ほどではないが十分な実装力 |
| レビュー・深い思考 | `copilot` | GPT-5.5 | Opus より賢い。洞察・設計分析に優れる。複数プロバイダー切替可能だが高価 |
| 設計判断を伴う実装 | Claude Code (自分) | Opus | 実装力は高いが低速。設計判断が必要なタスク向き |

## CLI 存在確認

マシンごとにインストール状況が異なる。
委譲前に `command -v` で確認し、不在なら自分で実行する。

| 委譲先 | 確認コマンド |
| --- | --- |
| `cursor-agent` | `command -v agent` |
| `copilot` | `command -v copilot` |
| `codex` | `command -v codex` |

## いつ誰に委譲するか

コードを書き始める前にタスクを分類する。

### cursor-agent（実装）— いずれか該当で委譲

- 3 ファイル以上の編集
- 本体コード＋テストの同時追加
- 反復的・定型的な変更、scaffold / boilerplate / 設定の結線
- 合意済みプランの適用、設計判断のないリファクタ

目的・制約・ファイル・検証コマンドを具体的に渡し、「提案」ではなく「編集」させる。
完了後に Claude Code が diff レビュー＋検証。

### copilot（レビュー・思考）

- 設計判断、バグ原因分析、複数案の比較、判断の裏取り
- read-only のみ。実装には使わない

### Claude Code（自分で実装）

- 1〜2 ファイル・数行の修正
- 試行錯誤が必要 / 設計判断が未解決のタスク
- ユーザーが直接やらせたいと明示
- 委譲先が未インストール・レート制限・認証エラー

## 安全規則

### 返却フォーマット

サブエージェントに以下で返却させる:
- 要約（1〜3 行）、変更ファイルパス一覧、未解決の質問・トレードオフ、`file:line` 引用

### 破壊的 git 禁止

委譲プロンプトに必ず含める:
- `git checkout` / `git restore` / `git stash` / `git reset` 禁止
- 許可は `git mv` と読み取り系のみ
- 委譲後に `git status --short` で dirty ファイルの生存を確認

過去に委譲先が `git checkout -- <file>` でユーザーの未コミット編集を破壊した事故あり。

## CLI 運用

| 項目 | cursor-agent | copilot |
| --- | --- | --- |
| モデル | `composer-2.5-fast` 固定 | `gpt-5.5`（第二意見は GPT 系優先） |
| 不可時 | フォールバックせず自分に戻す | — |
| 分析 | `--mode ask` / `--mode plan` | `--no-ask-user` |
| 実装 | `--force` | `--allow-all-tools`（明示委譲時のみ） |
| 深い推論 | — | `--effort high` |

## 委譲先の稼働監視

各 CLI は JSONL ストリーミング出力を持つ。委譲時はこれを使い、スタックや rate limit を検知する。

| CLI | JSONL フラグ | 活動イベント | 完了イベント |
| --- | --- | --- | --- |
| `agent` | `--output-format stream-json` | `assistant` | `result`（`is_error`, `duration_ms`） |
| `copilot` | `--output-format json` | `assistant.turn_start` | `result`（`exitCode`） |
| `codex` | `--json` | `turn.started` | `turn.completed`（`usage`） |

判定基準:
- 一定時間イベントが来ない → スタックの疑い（タイムアウトして自分に戻す）
- 活動イベントなしで完了 → rate limit / 認証エラーの可能性
- 事前に rate limit 残量を確認する API はない。実行して事後検知する

## 重要な判断はLLM間で議論する

議論の余地があり重要な判断は、ユーザーに問う前に GPT-5.5 と議論し結論を提示する。

- 決着がつくまで繰り返す（1 ターンで終えない）
- reasoning effort: 通常 `high`、複雑な判断 `xhigh`
- 既定 copilot → 不可時 codex へフォールバック（1 議論あたり 1 回まで。切替後は切替先で続行）
- 両方不可なら打ち切り、自分の見解を提示して CLAUDE.md「複数の選択肢がある場合」フローへ

```bash
# 初回
copilot -p "<議題>" --model gpt-5.5 --effort <high|xhigh> --no-ask-user
codex exec --sandbox read-only -c model_reasoning_effort='"<high|xhigh>"' "<議題>" </dev/null

# 継続（resume）
copilot --continue -p "<続き>" --no-ask-user        # 直近
copilot --resume=<id> -p "<続き>" --no-ask-user      # 特定セッション
codex exec resume --last "<続き>" </dev/null          # 直近
codex exec resume <session-id> "<続き>" </dev/null    # 特定セッション
```

## セッションの継続

同じ相手との継続は新規起動ではなく resume する。

| CLI | 直近を継続 | 特定セッション |
| --- | --- | --- |
| `copilot` | `copilot --continue -p "<続き>"` | `copilot --resume=<id> -p "<続き>"` |
| `codex` | `codex exec resume --last "<続き>"` | `codex exec resume <id> "<続き>"` |
| `cursor-agent` | `agent --continue -p "<続き>"` | `agent --resume <chatId> -p "<続き>"` |

ID 不明時は引数なし `--resume` でピッカーから選ぶ。
