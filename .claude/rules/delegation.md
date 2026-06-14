# AI委譲ルール

Claude Code (Opus) が実装を `cursor-agent`、レビュー/分析を `copilot` に委譲する判断基準と運用方針。
委譲は `Agent` ツール (`subagent_type: cursor-agent` または `copilot`) で行う。

## 委譲先の使い分け

| タスク種別 | 委譲先 | モデル | 主な理由 |
| --- | --- | --- | --- |
| 実装 (機能追加・修正・リファクタ) | `cursor-agent` | composer-2.5-fast | 定型実装の待ち時間が短い |
| レビュー・複雑な思考 (設計分析・難バグ調査・第二の意見) | `copilot` | gpt-5.5 (必要なら `--effort high`) | 設計比較と原因分析に使う |

新しい委譲先を追加する場合は、得意領域・禁止事項・フォールバック方針をこの表に追記する。
実装の既定は `cursor-agent`、レビューの既定は `copilot` のままにする。

## 委譲ゲート（実装に着手する前に必ず判定する）

コードを自分で書き始める前に、まずタスクを分類する。
frontmatter の description だけに任せず、ここで能動的に振り分ける。

### CLI 存在確認（委譲の前提条件）

委譲先の CLI はマシンごとにインストール状況が異なる。
委譲ゲートを通過した後、実際に委譲する前に `command -v <cli>` で存在を確認する。
不在なら Claude Code が自分で実行する。

| 委譲先 | 確認コマンド |
| --- | --- |
| `cursor-agent` | `command -v agent` |
| `copilot` | `command -v copilot` |
| `codex` | `command -v codex` |

### cursor-agent へ実装を委譲する（いずれか該当で委譲）

- 3 ファイル以上を編集する
- 本体コードとテストの両方を追加する
- 似たファイルへの反復的・定型的な変更
- scaffold / boilerplate / アダプタ / DTO / マイグレーション / 設定の結線
- すでに合意済みのプランの適用
- 設計・仕様の判断が残っていないリファクタリング

委譲時は、目的・制約・関与しそうなファイル・検証コマンドを具体的に渡し、「提案」ではなく「実際にコードを編集する」よう指示する。
完了後は Claude Code が diff をレビューし、検証を実行する。

### Claude Code が自分で実装してよい（次のいずれかのみ）

- 1〜2 ファイル・1〜数行の小さな修正
- 対話的に試行錯誤しながら進めるタスク
- 仕様・設計の判断が未解決のタスク（設計を固めてから cursor-agent へ委譲する）
- ユーザーが Claude Code に直接やらせたいと明示しているとき
- cursor-agent が未インストール・レート制限・認証エラーで動かないとき

### copilot へレビュー/思考を委譲する

- 設計の良し悪し判断、subtle なバグの原因分析、複数案の比較、自分の判断の裏取り
- read-only のレビュー/分析/第二意見/プラン批評にのみ使う
- ユーザーが明示しない限り、定型実装に copilot を使わない

## 委譲時に要求する返却フォーマット

サブエージェントの返却テキストは Claude Code のコンテキストに直接乗るため、出力を以下に揃えるよう指示する。

- 要約 (1〜3 行)
- 変更ファイルパス一覧 (実装系の場合)
- 未解決の質問・前提・トレードオフ
- 必要に応じて該当箇所の `file:line` 引用

## 委譲先の破壊的 git 禁止（厳守）

サブエージェントへの委譲プロンプトには、次を厳守事項として必ず入れる。

- `git checkout` / `git restore` / `git stash` / `git reset` 等の破壊的 git 操作を実行しない
- 使ってよい git は `git mv` と読み取り系（status / diff / log / show 等）のみ
- 委譲から戻ったら Claude Code 側で `git status --short` を取り、委譲前の dirty ファイルが生存しているか確認する

理由: 委譲先が「自分の変更を戻す」つもりで `git checkout -- <file>` を打ち、ユーザーの未コミット編集ごと破壊した事故が実際に起きた。
復旧は dropped stash の object hash 頼みになる。

## cursor-agent の運用

- 既定モデル: `composer-2.5-fast` 固定 (体感速度優先)
- rate limit / unavailable 時はフォールバックせず Claude Code に return する
- 分析のみは `--mode ask` / `--mode plan`、実装は `--force` を付ける
- 詳細は `~/.claude/agents/cursor-agent.md`

## copilot の運用

- 既定モデル: `gpt-5.5`
- レビュー/分析は read-only (`--no-ask-user`)、`--allow-all-tools` は実装を明示的に委譲したときのみ
- 推論を深めたいときは `--effort high`
- Anthropic 系モデル (claude-opus-4.x) を指定すると Claude と同系統の視点になるので、第二意見目的では GPT 系を優先する
- 詳細は `~/.claude/agents/copilot.md`

## 重要な判断は事前にLLM間で議論する

議論の余地があり、かつ内容が重要な場合は、ユーザーに問う前に gpt5.5 と議論し、その結論をユーザーへ提示する。

- 1ターンで終えず、LLM間で議論の決着がつくまで繰り返す
- 内容の複雑度に応じて reasoning effort を使い分ける
  - 通常: `high`
  - 複雑・難解な判断: `xhigh`
- 既定は copilot を使う。未インストール・レートリミット・認証エラー時は他方へフォールバックする（copilot → codex）
- 使用前に `command -v copilot` / `command -v codex` で CLI の存在を確認する（CLI 存在確認テーブルを参照）
  - copilot: `copilot -p "<議題>" --model gpt-5.5 --effort <high|xhigh> --no-ask-user`
  - codex: `codex exec --sandbox read-only -c model_reasoning_effort='"<high|xhigh>"' "<議題>" </dev/null`（model=gpt-5.5 は `~/.codex/config.toml` で既定。`</dev/null` で stdin を閉じないと入力待ちで hang する）
- 2ターン目以降は新規起動せず resume で文脈を引き継ぐ（下記「議論・セッションの継続」を参照）
  - copilot: `copilot --continue -p "<続き>" --no-ask-user`（特定セッションは `--resume=<id>`）
  - codex: `codex exec resume --last "<続き>" </dev/null`（特定セッションは `codex exec resume <session-id>`）
- フォールバックは1議論セッションあたり1回まで（A→B のみ。A→B→A の往復はしない）
- 両方とも不可用なら議論を打ち切り、その旨と暫定的な自分の見解をユーザーに伝えた上で「複数の選択肢がある場合」のフローへ進む
- 一度切替えたら、その議論セッション内の以降のターンは切替先で続行する（ターンごとに再切替しない）
- 決着後、議論の要点と最終結論をまとめてユーザーへ提示する
- そのうえでユーザーの判断が必要な選択が残る場合は、CLAUDE.md の「複数の選択肢がある場合」のフローに進む

## 議論・セッションの継続（resume）

同じ相手と議論や作業を継続するときは、新規起動ではなく前回セッションを resume する。直近セッションを継続するか、ID/名前/プレフィックスで特定セッションを指定する。

| CLI | 直近を継続 | 特定セッションを継続 |
| --- | --- | --- |
| `copilot` | `copilot --continue -p "<続き>"` | `copilot --resume=<id\|name\|prefix> -p "<続き>"` |
| `codex` | `codex exec resume --last "<続き>"` | `codex exec resume <session-id> "<続き>"` |
| `cursor-agent` | `agent --continue -p "<続き>"` | `agent --resume <chatId> -p "<続き>"` |

- ID を控えていないときは引数なしの `--resume`（codex は `codex exec resume`）でピッカーから選ぶ。
- 議論フロー（上記「重要な判断は事前にLLM間で議論する」）で同一論点を往復するときも、毎回新規起動せず resume で文脈を引き継ぐ。
- copilot は非対話でも `--no-ask-user` を付けたまま resume できる。codex exec は `</dev/null` で stdin を閉じる運用と併用する。
