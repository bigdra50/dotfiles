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

### Gradle で TLS ハンドシェイクが失敗する

**症状**: `Remote host terminated the handshake` + `The server may not support the client's requested TLS protocol versions`。`dl.google.com` への HTTPS 接続が失敗する。curl や Java の `HttpsURLConnection` では同じ URL に正常接続できる。

**原因1 — gradle.properties の TLS 制限**: `~/.gradle/gradle.properties` に `systemProp.https.protocols` や `org.gradle.jvmargs` 内の `-Dhttps.protocols` 設定があると、JDK の TLS ネゴシエーションが制限される。Gradle キャッシュがある間はネットワークアクセスが不要なため問題が顕在化しない。キャッシュ削除後に初めて失敗する。

```properties
# NG: 不要な TLS 制限（JDK 17+ はデフォルトで TLSv1.2/1.3 対応）
systemProp.https.protocols=TLSv1.2,TLSv1.3
org.gradle.jvmargs=-Xmx4096m -Dhttps.protocols=TLSv1.2,TLSv1.3

# OK: メモリ設定のみ
org.gradle.jvmargs=-Xmx4096m
```

**原因2 — 並列接続過多**: Gradle の並列ワーカーが `dl.google.com` へ同時に多数の TLS 接続を張り、一部がサーバー側から拒否される。キャッシュが空の初回ビルド時に発生しやすい。

**解決策**:

1. `~/.gradle/gradle.properties` から TLS 制限設定を除去
2. Gradle ワーカー数を制限して依存解決を通す:
```properties
org.gradle.workers.max=1
```
3. 設定変更後は Gradle デーモンの再起動が必須:
```bash
java -classpath "gradle-launcher.jar" org.gradle.launcher.GradleMain --stop
```
4. 依存がキャッシュされた後は `workers.max=1` を外して並列ビルドに戻せる

**切り分け手順**:
- `curl -sI <失敗URL>` で直接アクセス確認（HTTP 200 なら Gradle/JDK 固有の問題）
- `~/.gradle/gradle.properties` に `systemProp.https.*` がないか確認
- `-Djavax.net.debug=ssl:handshake` を `org.gradle.jvmargs` に追加して TLS 詳細を取得
- 成功/失敗ハンドシェイクの比率を確認（3/43 程度の失敗なら並列接続数の問題）
- デーモンが古い状態をキャッシュしている場合は `--stop` + `~/.gradle/daemon/` 削除

---

## Docker

### ポートが既に使用中で bind できない

**症状**: `docker run -p 8080:8080` で `address already in use`

**原因**: ホスト側の 8080 ポートが別プロセスで使用中

**解決策**:
```bash
# 使用中のプロセスを確認
lsof -i :8080

# 別ポートにマッピング
docker run -p 8090:8080 image-name
```

### コンテナ名の競合

**症状**: `docker run --name foo` で `The container name "/foo" is already in use`

**原因**: 起動失敗したコンテナが残っている

**解決策**:
```bash
docker rm foo && docker run --name foo ...
```

---

## その他

<!-- 上記カテゴリに当てはまらない問題 -->

---
