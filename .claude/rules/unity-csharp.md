---
paths: "**/Assets/**/*.cs"
---

# Unity C#

## アーキテクチャ

- MonoBehaviourは薄く保つ（ロジックは別クラスへ）
- ScriptableObjectで設定・データを外部化
- VContainer/ZenjectでDI
- Assembly Definitionで依存関係を明示

## 非同期処理

- UniTaskを優先（Coroutineより）
- CancellationTokenを適切に伝播
- async voidは避ける（UniTaskVoidを使用）
- UniRxでイベント駆動

## シリアライズ

- `[SerializeField]`でprivateフィールドを公開
- `[field: SerializeField]`でauto-propertyをシリアライズ
- 循環参照に注意

## パフォーマンス

- Update内でのアロケーションを避ける
- GetComponentはキャッシュ
- stringの結合はStringBuilder
- LINQのGCに注意（ホットパスでは避ける）

## ドメインリロード無効化対応

Enter Play Mode Settings で Domain Reload を無効化しても問題なく動作する実装を心がける。

### 静的フィールドのリセット

```csharp
// ❌ 悪い例: Play Mode終了後も値が残る
static int s_counter = 0;

// ✅ 良い例: RuntimeInitializeOnLoadMethodでリセット
static int s_counter = 0;

[RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.SubsystemRegistration)]
static void ResetStatics() => s_counter = 0;
```

### 静的イベントの購読

```csharp
// ❌ 悪い例: 再生のたびに重複登録される
static event Action OnSomething;
void OnEnable() => OnSomething += HandleSomething;

// ✅ 良い例: 登録前に解除、またはリセット処理
void OnEnable()
{
    OnSomething -= HandleSomething; // 重複防止
    OnSomething += HandleSomething;
}
void OnDisable() => OnSomething -= HandleSomething;
```

### シングルトンパターン

```csharp
// ❌ 悪い例: インスタンスが残り続ける
public class GameManager : MonoBehaviour
{
    public static GameManager Instance { get; private set; }
    void Awake() => Instance = this;
}

// ✅ 良い例: リセット処理を追加
public class GameManager : MonoBehaviour
{
    public static GameManager Instance { get; private set; }

    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.SubsystemRegistration)]
    static void ResetStatics() => Instance = null;

    void Awake() => Instance = this;
}
```

### 原則

- 静的フィールドは原則使用しない（DIで解決）
- やむを得ず使う場合は`[RuntimeInitializeOnLoadMethod]`でリセット
- `SubsystemRegistration`タイミングで初期化（最も早いタイミング）
- R3/UniRxの購読は`OnDestroy`で確実にDispose

## 参照ドキュメント

- Unity Manual: https://docs.unity3d.com/Manual/
- Unity Scripting API: https://docs.unity3d.com/ScriptReference/
- UnityCsReference: https://github.com/Unity-Technologies/UnityCsReference
