---
name: kb-unity
description: Unity開発のナレッジ。Unity API、エディタ拡張、パフォーマンス最適化、ベストプラクティス等
user-invocable: true
---

# Unity開発ナレッジ

Unity開発に関する学びを記録する。

## Unity API

### asmdef の versionDefines による条件付きコンパイル

特定のパッケージがインストールされている場合のみシンボルを定義し、そのパッケージのAPIを参照するコードをコンパイルエラーなしで扱える。

```json
{
    "versionDefines": [
        {
            "name": "com.example.optional-sdk",
            "expression": "",
            "define": "USE_OPTIONAL_SDK"
        }
    ]
}
```

- `name`: パッケージ名（`package.json`の`name`フィールド）
- `expression`: バージョン範囲（空文字 = 任意のバージョン、`[1.0,2.0)` = 範囲指定）
- `define`: 定義されるシンボル

ランタイムとエディタ両方の asmdef に設定が必要。`#if USE_OPTIONAL_SDK` で保護すれば、SDK未インストール環境でもコンパイルが通る。

---

## UIToolkit

### text-overflow: ellipsis が効く条件

テキスト省略（`...`）を機能させるには3つのプロパティをセットで指定する必要がある:

```css
white-space: nowrap;     /* 折り返し禁止 */
overflow: hidden;        /* はみ出し非表示 */
text-overflow: ellipsis; /* 省略記号表示 */
```

加えて、要素の幅が制約されていること（明示的な `width` 指定、または flex レイアウトによる制約）が必要。

ID + タイトルのように省略したくない部分とさせたい部分がある場合、要素を分離して flex プロパティで制御する:

```css
.item__id {
    flex-shrink: 0;          /* ID は縮小しない */
    white-space: nowrap;
}
.item__title {
    flex-grow: 1;
    flex-shrink: 1;          /* タイトル側が縮小 */
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
}
```

単一 Label に全テキストを入れると、どの部分が省略されるか制御できない。

### テキストのマーキー（横スクロール）アニメーション

ellipsis の代わりに、はみ出したテキストを横スクロールさせる手法。

構造:

```
mask (VisualElement, overflow: hidden, 幅制約あり)
  └─ label (Label, overflow: visible, flex-shrink: 0)
```

USS:

```css
.text-mask {
    overflow: hidden;
    flex-grow: 1;
    flex-shrink: 1;
}
.text-mask > .text-label {
    overflow: visible;
    flex-shrink: 0;       /* テキスト幅で伸びる */
    white-space: nowrap;
    text-overflow: clip;
}
```

C# でアニメーション:

```csharp
// レイアウト確定後に判定
label.RegisterCallback<GeometryChangedEvent>(_ =>
{
    float overflow = label.resolvedStyle.width - mask.resolvedStyle.width;
    if (overflow <= 0) return; // はみ出していなければ何もしない

    // schedule で毎フレーム left を更新
    float speed = 30f; // px/sec
    label.schedule.Execute(() =>
    {
        float t = (float)(Time.timeAsDouble % ((overflow + pause) / speed));
        label.style.left = -Mathf.Clamp(t * speed, 0, overflow);
    }).Every(16); // ≈60fps
});
```

注意点:
- `resolvedStyle.width` はレイアウト確定後でないと 0 を返す。`GeometryChangedEvent` で待つ
- テキストが変わるたびにアニメーションの再計算が必要
- 端で一時停止させるには時間ベースのステートマシンが必要

---

## エディタ拡張

### スクリプト再コンパイルを跨いだ処理の継続

パッケージインストール等でスクリプト再コンパイルが発生すると、Editor上の処理は中断される。再コンパイル後に処理を再開するパターン：

```csharp
public class SetupExample
{
    private static readonly string StateKey = "com.example.setup-in-progress";

    // 1. 処理開始時にSessionStateにフラグを保存
    public static async void StartSetup()
    {
        UnityEditor.PackageManager.Client.Add("com.example.package@1.0.0");
        SessionState.SetBool(StateKey, true);
        // ↑ここでスクリプト再コンパイルが走り、以降の処理は実行されない
    }

    // 2. 再コンパイル後に自動で呼ばれる
    [UnityEditor.Callbacks.DidReloadScripts]
    private static void OnScriptsReloaded()
    {
        if (!SessionState.GetBool(StateKey, false)) return;
        SessionState.SetBool(StateKey, false);
        ContinueSetup();
    }

    // 3. 残りの処理を実行（delayCallチェーンで段階的に）
    private static void ContinueSetup()
    {
        EditorApplication.delayCall += () =>
        {
            // Step1: 設定A
            EditorApplication.delayCall += () =>
            {
                // Step2: 設定B（Step1のUnity内部処理完了後に実行）
            };
        };
    }
}
```

要素の役割：

| 要素 | 役割 |
|------|------|
| `SessionState` | Editorセッション中のみ有効な一時ストレージ。再コンパイルを跨いで値を保持する（Editor再起動でリセット） |
| `[DidReloadScripts]` | スクリプト再コンパイル完了後に呼ばれるコールバック |
| `EditorApplication.delayCall` | 次のEditorフレームで実行。Unity内部処理の完了を待つために使用 |

注意点：
- `EditorPrefs` ではなく `SessionState` を使う。`EditorPrefs` はEditor再起動後も残るため、意図しない再実行が起きる
- `delayCall` チェーンが深くなると追跡が難しい。ステップ数が多い場合はキュー方式も検討
- 各ステップでのエラーハンドリングを忘れずに。途中で失敗してもフラグがリセットされるようにする

### XR Plug-in Management: XRLoader の切り替え

`XRPackageMetadataStore` を使ってXRローダーを有効化/無効化する。Project Settings > XR Plug-in Management のチェックボックス操作と同等。

```csharp
using UnityEditor.XR.Management;
using UnityEditor.XR.Management.Metadata;
using UnityEngine.XR.Management;

static void EnableXRPlugin(BuildTargetGroup group, string loaderType)
{
    // XRGeneralSettingsPerBuildTarget を取得または作成
    EditorBuildSettings.TryGetConfigObject(
        XRGeneralSettings.k_SettingsKey,
        out XRGeneralSettingsPerBuildTarget xrg);

    if (!xrg.HasSettingsForBuildTarget(group))
        xrg.CreateDefaultSettingsForBuildTarget(group);
    if (!xrg.HasManagerSettingsForBuildTarget(group))
        xrg.CreateDefaultManagerSettingsForBuildTarget(group);

    var mgr = xrg.ManagerSettingsForBuildTarget(group);

    // 既存ローダーを無効化
    foreach (var loader in mgr.activeLoaders.ToList())
        XRPackageMetadataStore.RemoveLoader(mgr, loader.GetType().ToString(), group);

    // 対象ローダーを有効化
    XRPackageMetadataStore.AssignLoader(mgr, loaderType, group);
}
```

loaderType の例：
- ARCore: `"UnityEngine.XR.ARCore.ARCoreLoader"`
- ARKit: `"UnityEngine.XR.ARKit.ARKitLoader"`
- OpenXR: `"UnityEngine.XR.OpenXR.OpenXRLoader"`

asmdef に `Unity.XR.Management` と `Unity.XR.Management.Editor` の参照が必要。

### OpenXR Feature の有効化（リフレクション経由）

OpenXR Feature の featureIdInternal は private field のため、リフレクションで取得する。

```csharp
var settings = OpenXRSettings.GetSettingsForBuildTargetGroup(group);
foreach (var feature in settings.GetFeatures())
{
    var field = feature.GetType().GetField(
        "featureIdInternal", BindingFlags.NonPublic | BindingFlags.Instance);
    var id = (string)field.GetValue(feature);
    if (id == targetFeatureId)
    {
        feature.enabled = true;
        EditorUtility.SetDirty(feature);
    }
}
```

---

## パフォーマンス最適化

<!-- プロファイリング、メモリ管理、描画最適化等 -->

---

## アーキテクチャ/設計パターン

### 並列エージェント開発のUnity固有制約

複数Claude Codeインスタンスでの並列開発をUnityプロジェクトに適用する際の制約と対策。

制約:
- シーン(.unity)やPrefab(.prefab)はバイナリ的なYAMLでgitマージが困難
- Unity Editor接続は1プロセスのみ（複数エージェントが同時にEditor操作できない）
- アセット依存関係が複雑で、1ファイルの変更が連鎖的に影響する
- テスト実行にEditor起動が必要（コンパイラのようにCLIだけで完結しない）

有効な並列分割の軸:
- プラットフォーム別（ARCore / ARKit / XREAL / Desktop）— 各asmdefで分離
- レイヤー別（Core / UseCase / Infrastructure / Presentation）— 依存方向が一方向なら衝突少
- 機能 x プラットフォームの直交分割 — 各エージェントが異なるバグに遭遇しやすい

実用的な構成:
- 2-3 worktree での並列 Claude Code セッション
- `current_tasks/` パターンでタスク衝突防止
- C#スクリプトのみの変更に限定すればgitマージは問題ない
- シーン/Prefab変更は1エージェントに集約する

<!-- MonoBehaviour設計、DI、イベントシステム等 -->

---

## トラブルシューティング

### Prefab Variant のネスト PrefabInstance で m_AddedComponents がビルド時に消失する

**症状**: Prefab Variant に追加したコンポーネント（`m_AddedComponents`）や子 GameObject（`m_AddedGameObjects`）が、Unity Editor では正常に見えるがビルド後のランタイムで存在しない。

**原因**: Prefab Variant がネストされた PrefabInstance を含む場合、追加コンポーネントのターゲット fileID が暗黙的/計算値（例: `7698955068414132531`）になる。Unity Editor はネスト PrefabInstance チェーンを辿って解決できるが、ビルドパイプラインは解決できず、`m_AddedComponents`/`m_AddedGameObjects` がサイレントに除外される。

**解決策**: Prefab Variant への YAML レベルのコンポーネント追加に頼らず、ランタイムで `AddComponent` する。設定値は ScriptableObject（DI 経由で注入）に持たせる。

```csharp
// Prefab Variant の制約を回避: ランタイムでコンポーネントを追加
var manager = xrOriginGo.AddComponent<ARTrackedImageManager>();
manager.referenceLibrary = config.ReferenceImageLibrary;
manager.enabled = true; // OnBeforeStart 再実行（後述）
```

**判別方法**: Prefab Variant YAML の `m_AddedComponents` のターゲット fileID がソース Prefab YAML に存在しない場合、暗黙的 fileID であり、ビルドで消失する可能性がある。

### ARFoundation の SubsystemLifecycleManager と AddComponent の実行順序

**症状**: `AddComponent<ARTrackedImageManager>()` でランタイム追加後、`enabled=False` になりサブシステムが起動しない。

**原因**: `AddComponent` 呼び出し時、Unity は即座に `OnEnable()` を実行する。`SubsystemLifecycleManager.OnEnable()` → `ARTrackedImageManager.OnBeforeStart()` の中で `enabled = (subsystem.imageLibrary != null)` が評価される。この時点ではまだ `referenceLibrary` を設定していないため、`imageLibrary` は null → `enabled = false`。

**解決策**: `referenceLibrary` 設定後に `manager.enabled = true` で再有効化する。

```csharp
var manager = go.AddComponent<ARTrackedImageManager>();
// ↑ OnEnable() が即実行 → imageLibrary==null → enabled=false

manager.referenceLibrary = library;  // サブシステムに library を設定
manager.enabled = true;              // OnEnable() → OnBeforeStart() 再実行
// ↑ 今度は imageLibrary!=null → enabled=true → subsystem.Start()
```

`SubsystemLifecycleManager.OnEnable()` 内で `subsystem.Start()` が呼ばれるため、XR Loader の `Start()` でそのサブシステムを明示的に起動していなくても問題ない。

### XREAL SDK の Image Tracking と Marker Tracking は別機能

XREAL SDK には2種類のトラッキングがあり、互換性がない:

| 機能 | Image Tracking | Marker Tracking |
|------|---------------|-----------------|
| 方式 | ARFoundation 標準（`ARTrackedImageManager` + `XRReferenceImageLibrary`） | XREAL 独自モジュール（別途インストール） |
| マーカー | 任意画像（最大5枚、同時1枚） | 事前定義カラーマーカー（ID 0-10） |
| 互換性 | ARCore/ARKit と共通コード | Image Tracking と非互換 |

ARFoundation ベースの Image Tracking を使う場合、XREAL の Marker Tracking モジュールは不要。XREAL SDK 3.x は `XRImageTrackingSubsystem` を実装しており、`ARTrackedImageManager` がそのまま動作する。

XREAL 固有の制約:
- Reference Image の `Keep Texture at Runtime` = `true` が必須
- 最大検出距離は画像物理サイズの約1.5倍
- 画像サイズ誤差は1cm以内

### Android ビルドで Gradle が TLS エラーになる

**症状**: `CommandInvokationFailure: Gradle build failed.` + `Remote host terminated the handshake`

**原因1 — gradle.properties の TLS 制限**: `~/.gradle/gradle.properties` に `systemProp.https.protocols` や `org.gradle.jvmargs` 内の `-Dhttps.protocols` 設定があると、JDK の TLS ネゴシエーションが制限されて Google Maven との接続が失敗する。キャッシュが存在する間は問題が顕在化しない。

```properties
# NG: 不要な TLS 制限（JDK 17+ はデフォルトで TLSv1.2/1.3 対応）
systemProp.https.protocols=TLSv1.2,TLSv1.3
systemProp.jdk.tls.client.protocols=TLSv1.2,TLSv1.3
org.gradle.jvmargs=-Xmx4096m -Dhttps.protocols=TLSv1.2,TLSv1.3

# OK: メモリ設定のみ
org.gradle.jvmargs=-Xmx4096m
```

**原因2 — 並列接続過多**: Gradle の並列ワーカーが `dl.google.com` へ同時に多数の TLS 接続を張り、一部がサーバー側から拒否される。キャッシュが空の初回ビルド時に発生しやすい。

**解決策**:
1. `~/.gradle/gradle.properties` から TLS 制限設定を除去
2. 並列接続が原因の場合、`Assets/Plugins/Android/gradleTemplate.properties` にワーカー数制限を追加:
```properties
org.gradle.workers.max=1
```
3. Gradle デーモンの再起動（設定変更後は必須）
4. 依存がキャッシュされた後は `workers.max=1` を外して並列ビルドに戻せる

**切り分け**:
- `curl -sI <失敗URL>` → HTTP 200 なら Gradle 固有の問題
- CLI から `--info` 付きで実行し `Searched in the following repositories` を確認
- `-Djavax.net.debug=ssl:handshake` を `org.gradle.jvmargs` に追加して TLS 詳細を取得

---

## 参考リンク

- [Unity Documentation](https://docs.unity3d.com/)
- [Unity Manual](https://docs.unity3d.com/Manual/)
