# XDG Base Directory

設定・データファイルの配置はXDG Base Directory仕様に従う。

| 変数 | デフォルト | 用途 |
|------|-----------|------|
| `$XDG_CONFIG_HOME` | `~/.config` | 設定ファイル |
| `$XDG_DATA_HOME` | `~/.local/share` | アプリデータ |
| `$XDG_STATE_HOME` | `~/.local/state` | 状態ファイル（ログ、履歴） |
| `$XDG_CACHE_HOME` | `~/.cache` | キャッシュ |

- ホームディレクトリ直下にドットファイルを新規作成しない
- ツールがXDGをサポートする場合は環境変数で設定パスを指定する
