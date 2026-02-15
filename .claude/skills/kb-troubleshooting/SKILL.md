---
name: kb-troubleshooting
description: 分野横断のトラブルシューティング集。遭遇した問題と解決策を記録
user-invocable: true
---

# トラブルシューティング集

プロジェクト横断で遭遇した問題と解決策を記録する。

## 記録フォーマット

問題を記録する際は以下の形式で:

```markdown
### [症状を簡潔に]

**症状**: 具体的な症状やエラーメッセージ

**原因**: 根本原因

**解決策**:
具体的な解決手順やコード
```

---

## 開発環境

<!-- IDE、ターミナル、OS固有の問題等 -->

---

## Git/バージョン管理

<!-- Git操作、マージ、履歴関連の問題等 -->

---

## ネットワーク/API

<!-- 通信エラー、認証、CORS等 -->

---

## ビルド/デプロイ

### Unity Build Support モジュールが見つからないように見える

**症状**: `PlaybackEngines/` を確認しても iOS/Android サポートが見つからない

**原因**: Unity Hub でインストールしたモジュールは `.app` 内ではなく、エディタルートに配置される

**解決策**:
正しいパスを確認する。macOS の場合:

```
/Applications/Unity/Hub/Editor/{VERSION}/
├── PlaybackEngines/          ← モジュールはここ
│   ├── AndroidPlayer/
│   ├── iOSSupport/
│   └── LinuxStandaloneSupport/
└── Unity.app/
    └── Contents/
        └── PlaybackEngines/  ← Mac Standalone のみ（ここを見ると不完全に見える）
```

モジュール一覧は `modules.json` で確認:
```bash
cat "/Applications/Unity/Hub/Editor/{VERSION}/modules.json" | jq '.[].id'
```

### Unity Hub CLI でモジュールを追加する

```bash
# 直接実行
"/Applications/Unity Hub.app/Contents/MacOS/Unity Hub" -- --headless \
  install-modules --version 6000.3.5f2 -m ios android --childModules

# unity-cli 経由（bigdra50/unity-cli）
uvx --from git+https://github.com/bigdra50/unity-cli \
  unity editor install 6000.3.5f2 -m ios -m android
```

`--childModules` を付けると Android SDK/NDK 等の依存モジュールも自動インストールされる。

### Gradle 並列ダウンロードで TLS ハンドシェイクが失敗する

**症状**: Unity Android ビルド（Gradle 8.13 + AGP 8.10.0）で `Remote host terminated the handshake` エラー。`dl.google.com` への HTTPS 接続がサーバー側から切断される。curl や Java の `HttpsURLConnection` では同じ URL に正常接続できる。

**原因**: Gradle の並列ワーカーが `dl.google.com` へ同時に多数の TLS 接続を張ると、一部のハンドシェイクがサーバー側から拒否される。キャッシュが空の初回ビルド時に発生しやすい。

**解決策**:

1. Gradle ワーカー数を制限して依存解決を通す:
```properties
# gradle.properties / gradleTemplate.properties
org.gradle.workers.max=1
```

2. CLI から直接実行する場合:
```bash
java -classpath "gradle-launcher.jar" org.gradle.launcher.GradleMain \
  "--no-daemon" "--max-workers=1" "assembleRelease"
```

3. 依存がキャッシュされた後は `workers.max=1` を外して並列ビルドに戻せる

**切り分け手順**:
- `curl -sI <失敗URL>` で直接アクセス確認（HTTP 200 なら Gradle 固有の問題）
- `--no-daemon` で途中まで成功するなら並列接続数の問題
- Gradle デーモンが古いネットワーク状態をキャッシュしている場合は `--stop` + `~/.gradle/daemon/` 削除

---

## その他

<!-- 上記カテゴリに当てはまらない問題 -->

---
