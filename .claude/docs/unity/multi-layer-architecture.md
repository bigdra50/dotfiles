# Unity多層設計アプローチ 設計指針

## 概要

Unity開発における多層設計アプローチは、アプリケーションをインゲーム（フレーム駆動）とアウトゲーム（イベント駆動）に分離し、MVP（Model-View-Presentation）パターンを採用することで、保守性と開発効率を向上させる設計手法です。

### 設計の目的

- **長期的に安定した運用を行える状況を作る**ことが最終目標
- アーキテクチャ自体が目的ではない
- 段階的な改善により自然と良い構造に収束させる

## 基本コンセプト

### アプリケーション分離の原則
- **インゲーム領域**: フレーム駆動（Update等のライフサイクル中心）
- **アウトゲーム領域**: イベント駆動（UI、設定、メニューなど）
- 明確な境界線を設けて保守性を向上

### アーキテクチャパターン
**MVP（Model-View-Presentation）** を採用
- **Model**: データとビジネスロジック
- **View**: UI表示とユーザー操作
- **Presentation**: ModelとViewの仲介役

## アーキテクチャ構成

### 層構成と責任分担

#### Core層
- 中核となるモデルとインターフェース定義
- Unityに依存しないピュアなC#コード
- ドメインロジックの集約

#### Core.UnityAdapter層
- CoreとUnity環境を接続するアダプター
- Unity固有の機能とCoreの橋渡し
- プラットフォーム依存性の吸収

#### Infrastructure層
- 具体的な実装とデータアクセス
- 外部サービスとの連携
- ファイルI/O、ネットワーク通信など

#### UseCase層
- ビジネスロジックの実行
- ユーザー操作に対する処理フロー
- CoreとInfrastructureの協調

#### View層
- UI表示とユーザーインタラクション
- MonoBehaviourベースのUnityコンポーネント
- Presentationから受け取った状態の反映

### 設計上の重要な工夫と原則

#### 依存関係の管理
```
View → Presentation → UseCase → Core ← Infrastructure
```
- 単方向の依存関係を維持
- 上位層は下位層に依存するが、逆は依存しない
- インターフェースを通じた疎結合

#### Assembly Definition（asmdef）の活用
- 各層をアセンブリとして分離
- 循環参照の防止をコンパイル時に検証
- ビルド時間の最適化

#### パッケージ構成例
```
├── Core/                    # ドメインモデル
├── Core.UnityAdapter/       # Unity連携
├── Infrastructure/          # 外部サービス連携
├── UseCases/               # ビジネスロジック
├── Views/                  # UI層
└── Http/                   # API通信
```

## 設計方針と利点

### 基本方針（多層設計アプローチの指針）

#### 1. UseCase層の必須化
- **必ず作成する**: ビジネスロジックの集約点として機能
- **テストのエントリーポイント**: シナリオテストの実装に活用
- **コード理解の入り口**: 未知の領域のコードを理解する際の起点

#### 2. モデルへのアクセス制限
- **Presenter → UseCase → Model**: この経路を厳守
- **直接アクセスの禁止**: PresenterからRepositoryへの直接アクセスは禁止
- **階層の維持**: 冗長になっても階層構造を守る

#### 3. 層間の関係性ルール
- **Presenter-View**: 1:1を厳守（密結合を防ぐ）
- **UseCase-Presenter**: 1:nを許容（複数のPresenterから利用可能）
- **UseCase-Repository**: n:mを許容（柔軟な組み合わせ）

#### 4. サービスクラスの使用制限
- **原則禁止**: 責任の不明確化を防ぐ
- **例外的使用**: 個人ブランチやFeatureFlag内での一時的使用のみ

### ServiceとUseCaseの違い

#### UseCase（推奨）
**ビジネスロジックの実行単位**
- **目的**: ユーザーの「やりたいこと」を表現
- **責務**: 一連の処理フローを制御
- **例**: `LoginUseCase`, `PurchaseItemUseCase`, `StartBattleUseCase`

```csharp
public class PurchaseItemUseCase
{
    private readonly IPlayerRepository _playerRepository;
    private readonly IItemRepository _itemRepository;
    
    public async UniTask<PurchaseResult> ExecuteAsync(string playerId, string itemId)
    {
        // 1. プレイヤー情報を取得
        var player = await _playerRepository.GetAsync(playerId);
        
        // 2. アイテム情報を取得
        var item = await _itemRepository.GetAsync(itemId);
        
        // 3. 購入可能かチェック
        if (!player.CanAfford(item.Price))
            return PurchaseResult.InsufficientFunds;
            
        // 4. 購入処理
        player.Purchase(item);
        
        // 5. 保存
        await _playerRepository.SaveAsync(player);
        
        return PurchaseResult.Success;
    }
}
```

#### Service（原則禁止）
**技術的な関心事や横断的機能**
- **目的**: 特定の技術的機能を提供
- **責務**: 再利用可能なユーティリティ
- **許容例**: `AudioService`, `LoggingService`, `AnalyticsService`

```csharp
// 避けるべきServiceの例
public class PlayerService  // ❌ 責任が不明確
{
    public void Attack() { }
    public void Move() { }
    public void SaveData() { }
    public void LoadData() { }
    // なんでもできるクラスになりがち
}

// 許容されるServiceの例
public class AudioService  // ✅ 明確な技術的責任
{
    public void PlaySE(string clipName) { }
    public void PlayBGM(string clipName) { }
    public void SetVolume(float volume) { }
}
```

#### 重要な違い

| 項目 | UseCase | Service |
|------|---------|----------|
| **スコープ** | ユーザーの1つのアクション | システム全体で使われる機能 |
| **依存関係** | Repository/Modelに依存 | 他の層から独立 |
| **テスト観点** | シナリオテストの起点 | 単体テストで独立検証 |
| **層での位置** | 明確（UseCase層） | 曖昧（どの層にも属さない） |

#### なぜServiceは原則禁止なのか

1. **責任の曖昧化**: 「〇〇Service」は何でも入れられる箱になりがち
2. **層の破壊**: どの層に属するか不明確
3. **UseCase化可能**: 多くの場合、UseCaseとして表現できる
4. **テストの複雑化**: 責任が曖昧なためテストが困難

ただし、**技術的な横断的関心事**（ログ、分析、音声など）は例外的にServiceとして実装することが許容されます。

### 設計の利点

#### 開発面での利点
- **認知負荷の軽減**: 「どの層を今触っているか」を明確に意識できる
- **保守性の向上**: 責任分担が明確で修正箇所を特定しやすい
- **テスタビリティ**: 各層を独立してテスト可能

#### 技術面での利点
- **循環参照の防止**: asmdefによるコンパイル時チェック
- **モジュール性**: 機能単位での独立開発が可能
- **プラットフォーム対応**: Core層はプラットフォーム非依存

## 実装上の課題と対策

#### 課題
- **ボイラープレートの増加**: 層間の接続コードが冗長になりがち
- **学習コストの高さ**: 設計に不慣れなメンバーの認知負荷
- **初期開発コスト**: 設計フェーズでの時間投資が必要

#### 対策
- **テンプレート化**: よく使用されるパターンのコード生成
- **段階的導入**: 一部機能から始めて徐々に適用範囲を拡大
- **ドキュメント整備**: 設計方針とパターンの明文化

## 実装指針

### 設計決定の指針

#### UseCase層の実装原則

```csharp
// UseCaseの基本構造
public class CreatePlayerUseCase
{
    private readonly IPlayerRepository _playerRepository;
    private readonly IPlayerFactory _playerFactory;
    
    public CreatePlayerUseCase(
        IPlayerRepository playerRepository,
        IPlayerFactory playerFactory)
    {
        _playerRepository = playerRepository;
        _playerFactory = playerFactory;
    }
    
    public async UniTask<CreatePlayerResult> ExecuteAsync(CreatePlayerRequest request)
    {
        // 1. バリデーション
        if (string.IsNullOrEmpty(request.Name))
            return CreatePlayerResult.InvalidName;
            
        // 2. 重複チェック
        var existingPlayer = await _playerRepository.FindByNameAsync(request.Name);
        if (existingPlayer != null)
            return CreatePlayerResult.NameAlreadyExists;
            
        // 3. プレイヤー作成
        var player = _playerFactory.Create(request.Name);
        
        // 4. 保存
        await _playerRepository.SaveAsync(player);
        
        return CreatePlayerResult.Success;
    }
}

// Presenterからの呼び出し
public class CreatePlayerPresenter
{
    private readonly CreatePlayerUseCase _useCase;
    
    private async UniTaskVoid OnCreateButtonClicked()
    {
        // UseCase経由でのみモデルにアクセス
        var result = await _useCase.ExecuteAsync(new CreatePlayerRequest(_view.NameInput));
        
        switch (result)
        {
            case CreatePlayerResult.Success:
                _view.ShowSuccessMessage();
                break;
            case CreatePlayerResult.NameAlreadyExists:
                _view.ShowError("その名前は既に使用されています");
                break;
        }
    }
}
```

#### 層の責任分担明確化
```csharp
// Good: 責任が明確
// Core層 - ドメインロジック
public class PlayerStatus
{
    public int Health { get; private set; }
    public bool IsDead => Health <= 0;
    
    public void TakeDamage(int damage)
    {
        Health = Math.Max(0, Health - damage);
    }
}

// View層 - UI表示のみ
public class HealthBarView : MonoBehaviour
{
    public void UpdateHealth(float healthRatio)
    {
        healthBar.fillAmount = healthRatio;
    }
}
```

#### 依存関係の一方向性維持
```csharp
// Good: 上位層から下位層への依存
public class PlayerPresenter
{
    private readonly IPlayerRepository _repository; // Infrastructure層への依存
    private readonly PlayerView _view; // View層への依存
    
    public void Initialize(PlayerView view, IPlayerRepository repository)
    {
        _view = view;
        _repository = repository;
    }
}

// Bad: 循環依存
// PlayerView が PlayerPresenter を参照し、
// PlayerPresenter が PlayerView を参照する構造は避ける
```

## 実装パターン

#### 1. インターフェース分離の原則

```csharp
// Good: 小さく特化したインターフェース
public interface IPlayerHealthReader
{
    int CurrentHealth { get; }
    int MaxHealth { get; }
    bool IsDead { get; }
}

public interface IPlayerHealthWriter
{
    void TakeDamage(int damage);
    void Heal(int amount);
}

// Bad: 巨大なインターフェース
public interface IPlayerEverything
{
    // 数十のプロパティとメソッド...
}
```

#### 2. データ転送オブジェクト（DTO）の活用

```csharp
// 層間でのデータ受け渡し用
public readonly struct PlayerStatusDto
{
    public readonly int Health;
    public readonly int MaxHealth;
    public readonly float HealthRatio;
    
    public PlayerStatusDto(int health, int maxHealth)
    {
        Health = health;
        MaxHealth = maxHealth;
        HealthRatio = (float)health / maxHealth;
    }
}

// Presenter → View
public void UpdatePlayerStatus(PlayerStatusDto status)
{
    _view.UpdateHealthBar(status.HealthRatio);
    _view.SetHealthText($"{status.Health}/{status.MaxHealth}");
}
```

#### 3. イベント駆動とリアクティブパターン

```csharp
// R3を使用したリアクティブな実装
public class PlayerPresenter : IDisposable
{
    private readonly CompositeDisposable _disposables = new();
    
    public void Initialize(IPlayerModel model, IPlayerView view)
    {
        // モデルの変更を監視してViewに反映
        model.HealthChanged
            .Select(health => new PlayerStatusDto(health, model.MaxHealth))
            .Subscribe(view.UpdatePlayerStatus)
            .AddTo(_disposables);
            
        // Viewからのイベントをモデルに伝達
        view.OnAttackButtonClicked
            .Subscribe(_ => model.Attack())
            .AddTo(_disposables);
    }
    
    public void Dispose() => _disposables.Dispose();
}
```

## プロジェクト構成

#### 1. Assembly Definition構成

```
Assets/
├── Core/
│   ├── Core.asmdef                    # 依存: なし
│   ├── Domain/
│   ├── Models/
│   └── Interfaces/
├── Infrastructure/
│   ├── Infrastructure.asmdef          # 依存: Core
│   ├── Repositories/
│   └── Services/
├── UseCases/
│   ├── UseCases.asmdef               # 依存: Core, Infrastructure
│   └── PlayerUseCases/
├── Presentation/
│   ├── Presentation.asmdef           # 依存: Core, UseCases
│   └── Presenters/
└── Views/
    ├── Views.asmdef                  # 依存: Core, Presentation
    └── UI/
```

#### 2. ディレクトリ命名規則

```csharp
// 機能単位での分割
├── Player/
│   ├── Core/PlayerModel.cs
│   ├── Presentation/PlayerPresenter.cs
│   ├── View/PlayerView.cs
│   └── Infrastructure/PlayerRepository.cs
├── Inventory/
│   ├── Core/InventoryModel.cs
│   ├── Presentation/InventoryPresenter.cs
│   └── View/InventoryView.cs
└── Combat/
    ├── Core/CombatSystem.cs
    ├── Presentation/CombatPresenter.cs
    └── View/CombatView.cs
```

## エラーハンドリング

#### 1. 層ごとの例外処理戦略

```csharp
// Core層: ドメイン例外のみ
public class PlayerModel
{
    public void TakeDamage(int damage)
    {
        if (damage < 0)
            throw new ArgumentException("Damage cannot be negative");
            
        if (IsDead)
            throw new InvalidOperationException("Cannot damage dead player");
    }
}

// Infrastructure層: 外部依存の例外を内部例外に変換
public class PlayerRepository : IPlayerRepository
{
    public async UniTask<Player> LoadAsync(string playerId)
    {
        try
        {
            return await _httpClient.GetPlayerAsync(playerId);
        }
        catch (HttpRequestException ex)
        {
            throw new PlayerLoadException($"Failed to load player {playerId}", ex);
        }
    }
}

// Presentation層: ユーザー向けエラーメッセージに変換
public class PlayerPresenter
{
    private async UniTaskVoid LoadPlayerAsync(string playerId)
    {
        try
        {
            var player = await _repository.LoadAsync(playerId);
            _view.ShowPlayer(player);
        }
        catch (PlayerLoadException)
        {
            _view.ShowError("プレイヤー情報の読み込みに失敗しました");
        }
    }
}
```

## パフォーマンス最適化

#### 1. オブジェクトプール活用

```csharp
// View層でのオブジェクトプール
public class UIElementPool : MonoBehaviour
{
    [SerializeField] private HealthBarView _prefab;
    private readonly Queue<HealthBarView> _pool = new();
    
    public HealthBarView Rent()
    {
        if (_pool.Count > 0)
            return _pool.Dequeue();
            
        return Instantiate(_prefab);
    }
    
    public void Return(HealthBarView element)
    {
        element.gameObject.SetActive(false);
        _pool.Enqueue(element);
    }
}
```

#### 2. バッチ処理パターン

```csharp
// 大量データの効率的な処理
public class InventoryPresenter
{
    public void UpdateManyItems(IEnumerable<ItemDto> items)
    {
        // View更新をバッチ化
        _view.BeginBatchUpdate();
        
        foreach (var item in items)
        {
            _view.UpdateItem(item);
        }
        
        _view.EndBatchUpdate(); // 一括でUI更新
    }
}
```

## テスト戦略

#### 1. 層別テスト戦略

```csharp
// Core層: 純粋なユニットテスト
[Test]
public void PlayerModel_TakeDamage_ReducesHealth()
{
    var player = new PlayerModel(maxHealth: 100);
    
    player.TakeDamage(30);
    
    Assert.That(player.Health, Is.EqualTo(70));
}

// Presentation層: モックを使用したテスト
[Test]
public void PlayerPresenter_PlayerDied_ShowsGameOverScreen()
{
    var mockView = new Mock<IPlayerView>();
    var mockModel = new Mock<IPlayerModel>();
    var presenter = new PlayerPresenter(mockView.Object, mockModel.Object);
    
    mockModel.Raise(m => m.PlayerDied += null, EventArgs.Empty);
    
    mockView.Verify(v => v.ShowGameOverScreen(), Times.Once);
}

// View層: 統合テスト
[UnityTest]
public IEnumerator PlayerView_UpdateHealth_UpdatesUI()
{
    var view = Object.Instantiate(playerViewPrefab);
    
    view.UpdateHealth(0.5f);
    yield return null; // UI更新を待機
    
    Assert.That(view.HealthBar.fillAmount, Is.EqualTo(0.5f).Within(0.01f));
}
```

#### 2. モック作成指針

```csharp
// インターフェースベースのモック作成
public interface IPlayerRepository
{
    UniTask<Player> LoadAsync(string id);
    UniTask SaveAsync(Player player);
}

// テストでのモック使用
public class PlayerRepositoryMock : IPlayerRepository
{
    private readonly Dictionary<string, Player> _players = new();
    
    public UniTask<Player> LoadAsync(string id)
    {
        return UniTask.FromResult(_players.GetValueOrDefault(id));
    }
    
    public UniTask SaveAsync(Player player)
    {
        _players[player.Id] = player;
        return UniTask.CompletedTask;
    }
}
```

## デバッグとログ

#### 1. 層別ログ戦略

```csharp
// Core層: ドメインイベントのログ
public class PlayerModel
{
    private static readonly ILogger Logger = LogManager.GetLogger<PlayerModel>();
    
    public void TakeDamage(int damage)
    {
        Logger.LogInfo($"Player taking {damage} damage, health: {Health} -> {Health - damage}");
        Health -= damage;
        
        if (IsDead)
        {
            Logger.LogInfo("Player died");
            PlayerDied?.Invoke();
        }
    }
}

// Infrastructure層: 外部通信のログ
public class PlayerRepository
{
    private static readonly ILogger Logger = LogManager.GetLogger<PlayerRepository>();
    
    public async UniTask<Player> LoadAsync(string id)
    {
        Logger.LogDebug($"Loading player: {id}");
        try
        {
            var result = await _httpClient.GetAsync($"/players/{id}");
            Logger.LogInfo($"Successfully loaded player: {id}");
            return result;
        }
        catch (Exception ex)
        {
            Logger.LogError($"Failed to load player: {id}", ex);
            throw;
        }
    }
}
```

#### 2. 開発用デバッグ機能

```csharp
#if UNITY_EDITOR
// エディタ用のデバッグ機能
[MenuItem("Debug/Player/Set Health to 10")]
private static void SetPlayerHealthLow()
{
    var presenter = FindObjectOfType<PlayerPresenter>();
    presenter?.DebugSetHealth(10);
}

// Runtime用のデバッグUI
public class DebugPlayerView : MonoBehaviour
{
    [SerializeField] private Button _damageButton;
    [SerializeField] private Button _healButton;
    
    private void Start()
    {
        _damageButton.onClick.AddListener(() => _presenter.DebugTakeDamage(10));
        _healButton.onClick.AddListener(() => _presenter.DebugHeal(10));
    }
}
#endif
```

## パフォーマンス監視

#### 1. 層ごとのパフォーマンス計測

```csharp
// Presentation層でのパフォーマンス監視
public class PlayerPresenter
{
    private readonly ProfilerMarker _updateMarker = new("PlayerPresenter.Update");
    
    private void Update()
    {
        using (_updateMarker.Auto())
        {
            UpdatePlayerStatus();
            UpdatePlayerInput();
        }
    }
}

// Infrastructure層での通信時間計測
public class PlayerRepository
{
    public async UniTask<Player> LoadAsync(string id)
    {
        var stopwatch = Stopwatch.StartNew();
        try
        {
            var result = await _httpClient.GetPlayerAsync(id);
            Logger.LogInfo($"Player load took {stopwatch.ElapsedMilliseconds}ms");
            return result;
        }
        finally
        {
            stopwatch.Stop();
        }
    }
}
```

## まとめ

Unity多層設計アプローチは、以下の要素により長期的に安定した運用を実現します：

1. **明確な責任分担**: 各層が持つ責任を厳密に定義
2. **テスト容易性**: UseCase層を中心としたテスト戦略
3. **保守性の向上**: 依存関係の管理と循環参照の防止
4. **段階的な改善**: 完璧を求めず、継続的に改善

> "クリーンアーキテクチャは『採用する』ものではなく『作っていったら自然とそうなる』ものである"

この言葉が示すように、アーキテクチャ自体を目的とせず、実際の開発を通じて自然に良い構造へ収束させることが重要です。

## 参考資料

- [Unity非ゲームアプリのクリーンアーキテクチャ](https://qiita.com/toRisouP/items/e5b312af53c40e1f4a80)
- [UnityScreenNavigator デモプロジェクト](https://github.com/Haruma-K/UnityScreenNavigator/tree/master/Assets/Demo)
- [Unity多層設計アプローチの紹介](https://zenn.dev/izm/articles/2478583453b235)