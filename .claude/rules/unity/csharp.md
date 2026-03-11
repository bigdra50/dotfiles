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

## パフォーマンス

- Update内でのアロケーションを避ける
- GetComponentはキャッシュ
- LINQのGCに注意（ホットパスでは避ける）

## ドメインリロード無効化対応

Domain Reload 無効時にも正しく動作する実装にする。

- 静的フィールドは原則使用しない（DIで解決）
- やむを得ず使う場合は `[RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.SubsystemRegistration)]` でリセット
- 静的イベントは `OnEnable` で `-=` してから `+=`、`OnDisable` で `-=`
- R3/UniRxの購読は `OnDestroy` で確実にDispose
