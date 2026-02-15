# Bark通知セットアップ

Claude Codeの作業完了・入力待ちをiPhoneへプッシュ通知する。

## 構成

```
Claude Code Hook --> notify.py --> bark-server (Docker) --> APNs --> iPhone
                        |
                        +--> osascript (macOSローカル通知)
```

- bark-server: 各PCでDockerコンテナとして稼働
- notify.py: `.claude/hooks/` に配置済み（dotfilesで管理）
- Bonjour (`.local`) でホスト名解決するため、IPアドレス固定不要

## 前提

- macOS
- Docker Desktop
- [Bark](https://apps.apple.com/app/bark-simple-push-notifications/id1403753865) iOS アプリ

## 手順

### 1. bark-server 起動

```bash
docker run -d --name bark-server --restart=always -p 8090:8080 finab/bark-server
```

ポート8080が使用中なら別のポートに変更し、`notify.py` の `BARK_PORT` も合わせる。

動作確認:

```bash
curl http://localhost:8090/ping
# {"code":200,"message":"pong"...}
```

### 2. iOSアプリにサーバー登録

Barkアプリで「サーバーを追加」から以下のアドレスを入力:

```
http://<LocalHostName>.local:8090
```

LocalHostNameは以下で確認:

```bash
scutil --get LocalHostName
```

登録後、テスト通知を送信して届くことを確認。

### 3. BARK_KEY 設定

iOSアプリに表示されるキーを `~/.zshenv_local` に追加:

```bash
export BARK_KEY="<your-key>"
```

シェルを再起動するか `source ~/.zshenv_local` で反映。

### 4. Claude Code Hook 設定

`~/.claude/settings.local.json` の `hooks` セクションに追加:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "python3 ~/.claude/hooks/notify.py --type stop",
            "async": true
          }
        ]
      }
    ],
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "python3 ~/.claude/hooks/notify.py --type idle_prompt",
            "async": true
          }
        ]
      }
    ]
  }
}
```

### 5. 動作確認

```bash
# 手動テスト
echo '{}' | python3 ~/.claude/hooks/notify.py --type stop

# ログ確認
tail -f ~/.local/state/bark-notify/notify.log
```

## 通知タイプ

| イベント | タイトル | 発火条件 |
|----------|----------|----------|
| stop | 完了 | タスク完了時 |
| idle_prompt | 入力待ち | ユーザー入力待ち |
| permission_prompt | 許可が必要 | 権限承認待ち |
| elicitation_dialog | 入力待ち | 選択肢への回答待ち |

## 複数PC運用

各PCで手順1-3を実施。notify.pyとhook設定はdotfilesで共有されるため、PCごとの設定は `BARK_KEY` のみ。

iOSアプリには各PCのサーバーをすべて登録する。通知タイトルにLocalHostNameが含まれるため、どのPCからの通知か識別できる。

## トラブルシューティング

### 通知が届かない

```bash
# bark-serverが動いているか
docker ps --filter name=bark-server

# 手動でcurlテスト
curl "http://$(scutil --get LocalHostName).local:8090/$BARK_KEY/test"

# ログ確認
tail ~/.local/state/bark-notify/notify.log
```

### ポート競合

```bash
# 使用中のポートを確認
lsof -i :8090

# コンテナを別ポートで再作成
docker rm -f bark-server
docker run -d --name bark-server --restart=always -p <別ポート>:8080 finab/bark-server
```

### iOSアプリからサーバーに接続できない

- PCとiPhoneが同一ネットワーク上にあるか確認
- `.local` 解決にはBonjourが必要（macOSでは標準で有効）
- ファイアウォールでポートがブロックされていないか確認
