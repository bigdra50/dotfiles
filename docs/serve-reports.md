# serve-reports — Claude Code レポートの LAN 公開

Claude Code が生成した HTML レポートを ghq 配下から集約し、miniserve で LAN に公開するグローバル mise タスク。
別マシンやスマホのブラウザからレポートを閲覧できる。

タスク本体: [`.config/mise/tasks/serve-reports`](../.config/mise/tasks/serve-reports)

## 前提

| 依存 | インストール |
|------|-------------|
| miniserve | `brew install miniserve` |
| ghq / fd | dotfiles の標準ツールセットに含まれる |

## 使い方

```bash
mise run serve-reports                    # 集約 + サーバ起動 (Ctrl-C で停止)
mise run serve-reports -- --collect-only  # 集約のみ (サーバは起動しない)
```

### 収集範囲の絞り込み (scope)

ghq root からのサブパスを引数に渡すと、その配下だけを収集する。
スラッシュを含まない引数は `github.com/<owner>` とみなす。

```bash
mise run serve-reports -- bigdra50                  # github.com/bigdra50 のみ
mise run serve-reports -- github.com/upfrontier     # 任意のホスト/owner 指定
mise run serve-reports -- bigdra50 upfrontier       # 複数 owner
mise run serve-reports -- --collect-only bigdra50   # 絞り込み + 集約のみ
```

無指定なら ghq 配下全体が対象。
scope は index.html のフッタと起動ログに表示される。

起動するとターミナルに URL と QR コードが表示される。

- 別マシン: `http://<ホスト名>.local:9080/` をブラウザで開く
- スマホ: QR コードを読み取る

トップページはレポート一覧 (更新日時降順) の自動生成 index。

## 環境変数

| 変数 | デフォルト | 用途 |
|------|-----------|------|
| `REPORTS_PORT` | `9080` | 公開ポート |
| `REPORTS_AUTH` | なし | Basic 認証 `user:pass`。社外秘を含む場合は推奨 |

```bash
REPORTS_AUTH=me:secret mise run serve-reports
```

## 収集対象と仕組み

収集対象は ghq 管理下の全リポジトリの以下 2 種類。

1. `<repo>/implementation-notes.html` (実装ノート)
2. `<repo>/.claude/reports/**/*.html` (html-reports スキルの出力)

```
ghq root
 ├── github.com/<owner>/<repo>/
 │    ├── implementation-notes.html ---+
 │    └── .claude/reports/ ------------+  symlink で集約 (実体はコピーしない)
 │                                     v
 │        $XDG_DATA_HOME/claude-reports/
 │         ├── index.html              <- 一覧を自動生成
 │         └── <owner>/<repo>/
 │              ├── implementation-notes.html -> 実体
 │              └── reports/ -> .claude/reports (dir symlink)
 │                                     |
 │                                miniserve :9080
 │                                     |
 +---- LAN ---------------------------+--> 別マシン / スマホ
```

- symlink 集約なので、レポートを書き直しても再集約は不要
- 新しいレポートファイルが増えたときだけタスクを再実行する
- `.claude/reports/` はディレクトリごと symlink するため、多ページ構成の相対リンクも壊れない
- 集約先はタスク実行のたびに作り直される (集約先に手動でファイルを置かないこと)

## トラブルシュート

### ログに `request parse error: invalid Header provided` が出る

平文 HTTP ポートに HTTP として解釈できないリクエストが届いたときのログで、実害はない。
サーバは 400 を返して動き続ける。

主な原因は 2 つ。

1. `https://` でのアクセス。TLS ハンドシェイクが不正ヘッダとして解釈される。最近の Chrome は HTTPS-First モードでスキーム省略時に https を先に試すため、URL 手入力時に起きやすい。`http://` を明示する (QR コード経由なら発生しない)
2. 社内 LAN のセキュリティスキャナによるポートプローブ

頻発して鬱陶しい場合は mkcert で証明書を作り miniserve の `--tls-cert` / `--tls-key` を使うか、Tailscale serve へ移行する。

### `<ホスト名>.local` が解決できない

mDNS が届かないネットワークセグメントでは `.local` 名は使えない。
起動ログに表示される IP 直打ち URL を使う。

### 別マシンからまったく届かない

社内 LAN のクライアント分離 (AP isolation) が原因の可能性が高い。
この場合 LAN サーバ方式は成立しないため、Tailscale serve へのフォールバックを検討する。

```bash
# 両マシンに Tailscale を導入した上で
tailscale serve --bg http://localhost:9080
```

### macOS のファイアウォールダイアログ

初回起動時に着信許可を求められたら「許可」を選ぶ。
拒否した場合はシステム設定 > ネットワーク > ファイアウォールで miniserve を許可する。
