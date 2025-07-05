# VContainer 実践ガイド - ジェリー農場ゲームから学ぶ設計パターン

## 目次
1. [VContainer導入の判断基準](#1-vcontainer導入の判断基準)
2. [基本設計原則](#2-基本設計原則)
3. [LifetimeScope階層設計](#3-lifetimescope階層設計)
4. [MVP+VContainer実装パターン](#4-mvpvcontainer実装パターン)
5. [コンポーネント分類と配置指針](#5-コンポーネント分類と配置指針)
6. [実装チェックリスト](#6-実装チェックリスト)
7. [トラブルシューティング](#7-トラブルシューティング)

---

## 1. VContainer導入の判断基準

### 1.1 導入すべきプロジェクト

**✅ 以下の条件に3つ以上該当する場合、導入を推奨**
- プロジェクト期間が6ヶ月以上
- チームメンバーが3人以上
- UI画面が10画面以上
- データ管理が複雑（セーブ/ロード、通信、複数のシステム間連携）
- テストの自動化を重視
- 長期運用を前提とした保守性が必要

### 1.2 導入を避けるべき場合

**❌ 以下の場合は導入を避ける**
- プロトタイプ・短期開発（3ヶ月未満）
- チーム全員がDI未経験
- シンプルなミニゲーム
- 学習コストを掛けられない状況

---

## 2. 基本設計原則

### 2.1 ジェリー農場ゲームでの適用例

ジェリー農場ゲームでは以下の原則が一貫して適用されています：

**Model-View-Presenter分離**
```csharp
// ❌ 悪い例：全てがMonoBehaviourに混在
public class BadJellyController : MonoBehaviour
{
    public int level;
    public int exp;
    public Text levelText;
    
    void Update()
    {
        // ビジネスロジック
        if (exp >= GetMaxExp()) LevelUp();
        
        // UI更新
        levelText.text = level.ToString();
        
        // 入力処理
        if (Input.GetMouseButtonDown(0)) GetExp();
    }
}

// ✅ 良い例：責任を分離
// Model: データのみ
public class JellyModel
{
    public ReactiveProperty<int> Level { get; } = new ReactiveProperty<int>(1);
    public ReactiveProperty<int> Exp { get; } = new ReactiveProperty<int>(0);
}

// View: 表示のみ
public class JellyView : MonoBehaviour
{
    [SerializeField] Text levelText;
    public Text LevelText => levelText;
}

// Presenter: 制御ロジック
public class JellyGrowUpPresenter : IInitializable
{
    readonly JellyModel model;
    readonly JellyView view;
    
    public JellyGrowUpPresenter(JellyModel model, JellyView view)
    {
        this.model = model;
        this.view = view;
    }
    
    public void Initialize()
    {
        model.Level.Subscribe(level => 
            view.LevelText.text = level.ToString());
    }
}
```

### 2.2 命名規則

ジェリー農場ゲームの命名規則を採用：

| 種類 | 接尾辞 | 例 |
|------|--------|-----|
| LifetimeScope | Context | `MainContext`, `JellyModalContext` |
| Model | Model | `CurrencyModel`, `FieldModel` |
| View | View | `MainSheetView`, `JellyView` |
| Presenter | Presenter | `MainSheetPresenter`, `JellyClickPresenter` |
| System | System | `ShopSystem`, `GrowUpSystem` |

---

## 3. LifetimeScope階層設計

### 3.1 推奨階層構造（ジェリー農場ゲーム準拠）

```
AppContext (アプリケーションルート)
├── MainContext (メインシーン)
│   ├── MainSheetContext (メインUI)
│   ├── JellyModalContext (ジェリーショップモーダル)
│   ├── PlantModalContext (アップグレードモーダル)
│   └── JellyContext (個別ジェリーユニット) × N個
```

### 3.2 各Contextの責任と実装例

#### AppContext（アプリケーションレベル）
**責任**: 全シーン共通の設定とサービス

```csharp
public class AppContext : LifetimeScope
{
    [SerializeField] UISetting uISetting;
    [SerializeField] MainSetting mainSetting;
    
    protected override void Configure(IContainerBuilder builder)
    {
        // ✅ 全シーン共通の設定
        builder.RegisterInstance(uISetting);
        builder.RegisterInstance(mainSetting);
        
        // ✅ グローバルマネージャー
        builder.RegisterEntryPoint<SoundManager>().AsSelf();
        
        // ✅ マスターデータ
        JellyFarmDBModel.LoadDB("JellyPreset", "Currency", "Field", "Upgrade", "Plant");
        builder.RegisterInstance(JellyFarmDBModel);
    }
}
```

**判断基準**: 以下に該当するものはAppContextで登録
- シーン遷移しても残る必要があるもの
- 設定データ（ScriptableObject）
- サウンドマネージャー
- マスターデータ

#### MainContext（シーンレベル）
**責任**: シーン固有のシステムとモデル

```csharp
public class MainContext : LifetimeScope
{
    [SerializeField] MainFolderModel mainFolderModel;
    
    protected override void Configure(IContainerBuilder builder)
    {
        // ✅ シーン固有のシステム
        builder.Register<ShopSystem>(Lifetime.Singleton);
        builder.Register<UpgradeSystem>(Lifetime.Singleton);
        builder.RegisterEntryPoint<SaveSystem>().AsSelf();
        
        // ✅ シーン全体で共有するモデル
        builder.RegisterInstance(mainFolderModel);
        builder.Register<CurrencyModel>(Lifetime.Singleton);
        builder.Register<FieldModel>(Lifetime.Singleton);
        builder.Register<UpgradeModel>(Lifetime.Singleton);
        
        // ✅ シーン全体のPresenter
        builder.RegisterEntryPoint<BackPresenter>();
    }
}
```

**判断基準**: 以下に該当するものはMainContextで登録
- シーン内の全UI・ユニットで共有するデータ
- ゲームシステム（ショップ、アップグレード等）
- セーブ/ロードシステム

#### UIContext（UI/モーダルレベル）
**責任**: 特定のUI画面の制御

```csharp
public class JellyModalContext : LifetimeScope
{
    [SerializeField] JellyModalView view;
    
    protected override void Configure(IContainerBuilder builder)
    {
        // ✅ このUI固有のモデル
        builder.Register<UIModel>(Lifetime.Scoped);
        
        // ✅ このUIのView
        builder.RegisterInstance(view);
        
        // ✅ このUIのPresenter
        builder.RegisterEntryPoint<JellyModalPresenter>();
    }
}
```

**判断基準**: 以下に該当するものはUIContextで登録
- 特定のUI画面でのみ使用するデータ
- そのUI画面のViewコンポーネント
- そのUI画面の制御Presenter

#### UnitContext（ユニットレベル）
**責任**: 個別ユニット（ジェリー）の制御

```csharp
public class JellyContext : LifetimeScope
{
    [SerializeField] JellyModel model;
    
    protected override void Configure(IContainerBuilder builder)
    {
        // ✅ ユニット固有のシステム
        builder.Register<ClickerSystem>(Lifetime.Singleton);
        builder.Register<GrowUpSystem>(Lifetime.Singleton);
        
        // ✅ このユニットのモデル
        builder.RegisterInstance(model);
        
        // ✅ このユニットのView（GameObject自体）
        builder.RegisterComponent(gameObject);
        builder.RegisterComponent(GetComponent<Animator>());
        
        // ✅ このユニットの各Presenter（機能別に分割）
        builder.RegisterEntryPoint<JellyAIPresenter>();
        builder.RegisterEntryPoint<JellyClickPresenter>();
        builder.RegisterEntryPoint<JellyDragPresenter>();
        builder.RegisterEntryPoint<JellyGrowUpPresenter>();
    }
}
```

**判断基準**: 以下に該当するものはUnitContextで登録
- 個別ユニットの状態データ
- ユニット固有の機能システム
- そのユニットの複数のPresenter（機能別）

---

## 4. MVP+VContainer実装パターン

### 4.1 Presenterの実装パターン

ジェリー農場ゲームでは、Presenterの役割を以下3つに分類しています：

#### パターンA: Model監視型Presenter
**用途**: Model変更をViewに反映

```csharp
public class MainSheetPresenter : IInitializable
{
    readonly CurrencyModel currencyModel;
    readonly MainSheetView view;
    readonly SoundManager soundManager;
    
    public MainSheetPresenter(
        CurrencyModel currencyModel, 
        MainSheetView view,
        SoundManager soundManager)
    {
        this.currencyModel = currencyModel;
        this.view = view;
        this.soundManager = soundManager;
    }
    
    public void Initialize()
    {
        InitializeModel();
        InitializeView();
    }
    
    void InitializeModel()
    {
        // ✅ Model変更をViewに自動反映
        currencyModel.Gelatin
            .Subscribe(gelatin => view.GelatinText.text = gelatin.ToString("N0"))
            .AddTo(Context);
            
        currencyModel.Gold
            .Subscribe(gold => view.GoldText.text = gold.ToString("N0"))
            .AddTo(Context);
    }
    
    void InitializeView()
    {
        // ✅ View入力をシステムに伝達
        view.JellyButton.OnClickAsObservable()
            .Subscribe(_ => {
                ModalContainer.Main.NextAsync<JellyModalContext>().Forget();
                soundManager.PlaySfx(uISetting.Button);
            })
            .AddTo(Context);
    }
}
```

#### パターンB: 入力処理型Presenter
**用途**: ユーザー入力の処理

```csharp
public class JellyClickPresenter : IInitializable
{
    readonly ClickerSystem clickerSystem;
    readonly LifetimeScope context;
    
    public JellyClickPresenter(ClickerSystem clickerSystem, LifetimeScope context)
    {
        this.clickerSystem = clickerSystem;
        this.context = context;
    }
    
    public void Initialize()
    {
        InitializeView();
    }
    
    void InitializeView()
    {
        // ✅ 入力をシステムに伝達
        context.OnMouseDownAsObservable()
            .Subscribe(_ => clickerSystem.Click(context))
            .AddTo(context.gameObject);
    }
}
```

#### パターンC: スケジューラー型Presenter
**用途**: 時間ベースの処理

```csharp
public class JellyGrowUpPresenter : IInitializable
{
    readonly JellyModel model;
    readonly GrowUpSystem growUpSystem;
    readonly LifetimeScope context;
    
    public JellyGrowUpPresenter(
        JellyModel model, 
        GrowUpSystem growUpSystem, 
        LifetimeScope context)
    {
        this.model = model;
        this.growUpSystem = growUpSystem;
        this.context = context;
    }
    
    public void Initialize()
    {
        InitializeModel();
        InitializeScheduler();
    }
    
    void InitializeModel()
    {
        // ✅ レベルアップ判定
        model.Exp
            .Where(exp => exp >= maxExp)
            .Subscribe(exp => growUpSystem.LevelUp(context))
            .AddTo(context.gameObject);
    }
    
    void InitializeScheduler()
    {
        // ✅ 定期実行処理
        Observable.Interval(TimeSpan.FromSeconds(1))
            .TakeWhile(_ => model.Level.Value < maxLevel)
            .Where(_ => context.gameObject.activeInHierarchy)
            .Subscribe(_ => growUpSystem.GetExpByTime(context))
            .AddTo(context.gameObject);
    }
}
```

### 4.2 Presenter分割の判断基準

**1つのPresenterにまとめる場合**
- 処理が単純（10行程度以内）
- 密接に関連する機能

**複数のPresenterに分割する場合**
- 異なる入力種類（クリック、ドラッグ、時間）
- 独立したライフサイクル
- テストを個別に行いたい機能

---

## 5. コンポーネント分類と配置指針

### 5.1 System（システム）の設計

**責任**: 複数のユニットやUIにまたがるゲームロジック

```csharp
// ✅ 良いSystemの例
public class ShopSystem
{
    readonly CurrencyModel currencyModel;
    readonly FieldModel fieldModel;
    readonly JellyFarmDBModel jellyFarmDBModel;
    
    // プロパティで状態を外部に公開
    public bool IsActiveSell { get; set; }
    
    public ShopSystem(
        CurrencyModel currencyModel,
        FieldModel fieldModel, 
        JellyFarmDBModel jellyFarmDBModel)
    {
        this.currencyModel = currencyModel;
        this.fieldModel = fieldModel;
        this.jellyFarmDBModel = jellyFarmDBModel;
    }
    
    // 具体的なアクションメソッド
    public void Buy(int jellyId) { /* 購入処理 */ }
    public bool Unlock(int jellyId) { /* アンロック処理 */ }
    public void Sell(JellyContext jellyContext) { /* 売却処理 */ }
}
```

**配置基準**: MainContextで`Lifetime.Singleton`

### 5.2 Model（データ）の設計

#### ReactivePropertyを使ったModel
```csharp
public class CurrencyModel
{
    public ReactiveProperty<int> Gelatin { get; } = new ReactiveProperty<int>(0);
    public ReactiveProperty<int> Gold { get; } = new ReactiveProperty<int>(0);
    
    // ✅ ビジネスルールもModelに含める
    public void AddGelatin(int amount)
    {
        Gelatin.Value += amount;
    }
    
    public bool CanSpendGold(int amount)
    {
        return Gold.Value >= amount;
    }
}
```

#### ScriptableObjectを使ったModel
```csharp
[CreateAssetMenu(fileName = "MainSetting", menuName = "Settings/MainSetting")]
public class MainSetting : ScriptableObject
{
    [SerializeField] Vector2 minRange;
    [SerializeField] Vector2 maxRange;
    
    public Vector2 RandomPositionInField => 
        new Vector2(
            Random.Range(minRange.x, maxRange.x),
            Random.Range(minRange.y, maxRange.y)
        );
}
```

**配置基準**:
- 全シーン共通: AppContextで`RegisterInstance`
- シーン固有: MainContextで`Lifetime.Singleton`
- UI固有: UIContextで`Lifetime.Scoped`

### 5.3 View（表示）の設計

```csharp
public class MainSheetView : MonoBehaviour
{
    [Header("UI Elements")]
    [SerializeField] Text gelatinText;
    [SerializeField] Text goldText;
    [SerializeField] Button jellyButton;
    [SerializeField] Button plantButton;
    [SerializeField] Button sellButton;
    
    // ✅ プロパティで外部アクセスを提供
    public Text GelatinText => gelatinText;
    public Text GoldText => goldText;
    public Button JellyButton => jellyButton;
    public Button PlantButton => plantButton;
    public Button SellButton => sellButton;
    
    // ❌ ビジネスロジックは含めない
    // ❌ 他のコンポーネントへの直接アクセスは避ける
}
```

**配置基準**: 該当するContextで`RegisterInstance`または`RegisterComponent`

---

## 6. 実装チェックリスト

### 6.1 新しい機能追加時のチェックリスト

**ステップ1: 責任の分析**
- [ ] この機能はどのレベル（App/Scene/UI/Unit）に属するか？
- [ ] Model/View/Presenterのどれに該当するか？
- [ ] 既存のSystemに追加するか、新しいSystemが必要か？

**ステップ2: 配置先の決定**
- [ ] 適切なContextが存在するか？
- [ ] 新しいContextが必要か？
- [ ] Lifetimeは適切か？（Singleton/Scoped/Transient）

**ステップ3: 依存関係の確認**
- [ ] 循環依存は発生していないか？
- [ ] 親Contextの要素に適切にアクセスできるか？
- [ ] 子Contextに不要な依存を注入していないか？

**ステップ4: UniRx/Disposable管理**
- [ ] AddTo()でメモリリークを防いでいるか？
- [ ] 適切なGameObjectまたはCompositeDisposableを指定しているか？

### 6.2 コードレビューチェックポイント

**Model**
- [ ] ReactivePropertyを適切に使用しているか？
- [ ] ビジネスルールがModelに含まれているか？
- [ ] UI依存のコードが含まれていないか？

**View**
- [ ] ビジネスロジックが含まれていないか？
- [ ] SerializeFieldとプロパティが適切に使い分けられているか？
- [ ] 他のViewコンポーネントに直接アクセスしていないか？

**Presenter**
- [ ] InitializeModel()とInitializeView()に適切に分離されているか？
- [ ] AddTo()でDispose管理されているか？
- [ ] 単一責任原則に従っているか？

**System**
- [ ] 複数のコンポーネントにまたがる処理を適切に統括しているか？
- [ ] Modelの状態変更を責任もって行っているか？

---

## 7. トラブルシューティング

### 7.1 よくある問題と解決法

#### 問題1: NullReferenceException発生
**症状**: Presenterで依存オブジェクトがnullになる

**原因と解決**:
```csharp
// ❌ 問題のあるコード
public class BadPresenter : IInitializable
{
    SomeService service; // Injectされていない
    
    public void Initialize()
    {
        service.DoSomething(); // NullReferenceException
    }
}

// ✅ 修正版
public class GoodPresenter : IInitializable
{
    readonly SomeService service;
    
    // コンストラクタで依存を受け取る
    public GoodPresenter(SomeService service)
    {
        this.service = service;
    }
    
    public void Initialize()
    {
        service.DoSomething(); // OK
    }
}
```

#### 問題2: メモリリーク
**症状**: シーン遷移後もObservableが動作し続ける

**解決**:
```csharp
// ✅ 正しいDispose管理
Observable.Timer(TimeSpan.FromSeconds(1))
    .Subscribe(_ => DoSomething())
    .AddTo(context.gameObject); // 重要: GameObjectのライフサイクルに合わせる
```

#### 問題3: 循環依存エラー
**症状**: VContainerで循環依存エラーが発生

**解決**: 依存関係を見直し、適切な階層に分割
```csharp
// ❌ 循環依存
class A { public A(B b) {} }
class B { public B(A a) {} }

// ✅ 修正: 共通の依存を抽出
class A { public A(ISharedService service) {} }
class B { public B(ISharedService service) {} }
class SharedService : ISharedService {}
```

### 7.2 デバッグのコツ

**1. VContainer Diagnostics利用**
- Window > VContainer > Diagnosticsでコンテナの状態を確認

**2. ログ出力による確認**
```csharp
public void Initialize()
{
    Debug.Log($"[{GetType().Name}] Initialize開始");
    // 初期化処理
    Debug.Log($"[{GetType().Name}] Initialize完了");
}
```

**3. 段階的構築**
- 最小限の構成から開始
- 一つずつ機能を追加して問題を特定

---

---

## 8. 参考資料とリポジトリ

### 8.1 参考リポジトリ

**ジェリー農場ゲーム（韓国語版 - 詳細なアーキテクチャ解説付き）**
- リポジトリ: https://github.com/jinhosung96/Unity-VContainer-UniRx-MVP-Example
- 特徴: VContainer + UniRx + MVP パターンの完全な実装例
- 参考ポイント: 
  - 4層のLifetimeScope階層設計
  - Reactive Presenterパターンの実装
  - 詳細な設計思想の解説（韓国語）

**TebakAngka（数字当てゲーム）**
- リポジトリ: https://github.com/ripandy/TebakAngka
- 使用技術: Unity 2020.3.8f1, UniTask 2.2.5, MessagePipe 1.3.3, VContainer 1.8.1
- 参考ポイント: MessagePipeとの組み合わせ例

### 8.2 ジェリー農場ゲームの具体的な実装例

#### Context階層の実装
```csharp
// AppContext.cs - アプリケーションレベル
public class AppContext : LifetimeScope
{
    [SerializeField] UISetting UISetting;
    [SerializeField] MainSetting MainSetting;
    
    protected override void Configure(IContainerBuilder builder)
    {
        // Setting 等録
        builder.RegisterInstance(UISetting);
        builder.RegisterInstance(MainSetting);
        
        // Manager 登録
        builder.RegisterEntryPoint<SoundManager>().AsSelf();
        
        // Model 登録
        JellyFarmDBModel.LoadDB("JellyPreset", "Currency", "Field", "Upgrade", "Plant");
        builder.RegisterInstance(JellyFarmDBModel);
    }
}

// MainContext.cs - シーンレベル
public class MainContext : LifetimeScope
{
    [SerializeField] MainFolderModel MainFolderModel;
    
    protected override void Configure(IContainerBuilder builder)
    {
        // System 登録
        builder.Register<ShopSystem>(Lifetime.Singleton);
        builder.Register<UpgradeSystem>(Lifetime.Singleton);
        builder.RegisterEntryPoint<SaveSystem>().AsSelf();
        
        // Model 登録
        builder.RegisterInstance(MainFolderModel);
        builder.Register<CurrencyModel>(Lifetime.Singleton);
        builder.Register<FieldModel>(Lifetime.Singleton);
        builder.Register<UpgradeModel>(Lifetime.Singleton);
        
        // Presenter 登録
        builder.RegisterEntryPoint<BackPresenter>();
    }
}

// JellyContext.cs - ユニットレベル
public class JellyContext : LifetimeScope
{
    [SerializeField] JellyModel Model;
    
    protected override void Configure(IContainerBuilder builder)
    {
        // System 登録
        builder.Register<ClickerSystem>(Lifetime.Singleton);
        builder.Register<GrowUpSystem>(Lifetime.Singleton);
        
        // Model 登録
        builder.RegisterInstance(Model);
        
        // View 登録
        builder.RegisterComponent(gameObject);
        builder.RegisterComponent(Animator);
        
        // Presenter 登録（機能別に分割）
        builder.RegisterEntryPoint<JellyAIPresenter>();
        builder.RegisterEntryPoint<JellyClickPresenter>();
        builder.RegisterEntryPoint<JellyDragPresenter>();
        builder.RegisterEntryPoint<JellyGrowUpPresenter>();
    }
}
```

#### Reactive Presenter の実装例
```csharp
// JellyGrowUpPresenter.cs - スケジューラー型Presenter
public class JellyGrowUpPresenter : IInitializable
{
    readonly JellyModel model;
    readonly GrowUpSystem growUpSystem;
    readonly LifetimeScope Context;
    readonly int maxExp = 100;
    readonly int maxLevel = 5;
    
    public JellyGrowUpPresenter(JellyModel model, GrowUpSystem growUpSystem, LifetimeScope Context)
    {
        this.model = model;
        this.growUpSystem = growUpSystem;
        this.Context = Context;
    }
    
    public void Initialize()
    {
        InitializeModel();
        InitializeScheduler();
    }
    
    void InitializeModel()
    {
        // Model의 경험치 데이터가 갱신됬을 때 최대 경험치를 충족 시켰을 시 레벨 업 처리
        model.Exp.Where(exp => exp >= maxExp)
            .Subscribe(exp => growUpSystem.LevelUp(Context))
            .AddTo(Context.gameObject);
            
        model.Level
            .Subscribe(_ => growUpSystem.LevelUpEvent(Context))
            .AddTo(Context.gameObject);
    }
    
    void InitializeScheduler()
    {
        // 1초마다 경험치 획득
        Observable.Interval(TimeSpan.FromSeconds(1))
            .TakeWhile(_ => model.Level.Value < maxLevel)
            .Where(_ => Context.gameObject.activeInHierarchy)
            .Subscribe(_ => growUpSystem.GetExpByTime(Context))
            .AddTo(Context.gameObject);
            
        // 3초마다 Gelatin 획득
        Observable.Interval(TimeSpan.FromSeconds(3f))
            .Where(_ => Context.gameObject.activeInHierarchy)
            .Subscribe(_ => growUpSystem.AutoGetGelatin(Context))
            .AddTo(Context.gameObject);
    }
}

// MainSheetPresenter.cs - Model監視型Presenter
public class MainSheetPresenter : IInitializable
{
    readonly CurrencyModel currencyModel;
    readonly MainSheetView view;
    readonly ShopSystem shopSystem;
    readonly SoundManager soundManager;
    readonly UISetting uISetting;
    
    public MainSheetPresenter(
        CurrencyModel currencyModel,
        MainSheetView view,
        ShopSystem shopSystem,
        SoundManager soundManager,
        UISetting uISetting)
    {
        this.currencyModel = currencyModel;
        this.view = view;
        this.shopSystem = shopSystem;
        this.soundManager = soundManager;
        this.uISetting = uISetting;
    }
    
    public void Initialize()
    {
        InitializeModel();
        InitializeView();
    }
    
    void InitializeModel()
    {
        // CurrencyModel의 젤라틴 및 골드 데이터가 갱신될 시 이를 UI 텍스트에 반영한다.
        currencyModel.Gelatin
            .Subscribe(gelatin => view.GelatinText.text = gelatin.ToString("N0"))
            .AddTo(Context);
            
        currencyModel.Gold
            .Subscribe(gold => view.GoldText.text = gold.ToString("N0"))
            .AddTo(Context);
    }
    
    void InitializeView()
    {
        // 젤리 버튼을 클릭 시 JellySheet를 연다.
        view.JellyButton.OnClickAsObservable()
            .Subscribe(_ => {
                ModalContainer.Main.NextAsync<JellyModalContext>().Forget();
                soundManager.PlaySfx(uISetting.Button);
            })
            .AddTo(Context);
            
        // 판매 버튼 위에 손가락을 올려진 상태인지를 체크한다.
        view.SellButton.OnPointerEnterAsObservable()
            .Subscribe(_ => shopSystem.IsActiveSell = true)
            .AddTo(Context);
            
        view.SellButton.OnPointerExitAsObservable()
            .Subscribe(_ => shopSystem.IsActiveSell = false)
            .AddTo(Context);
    }
}
```

### 8.3 公式ドキュメントとコミュニティ

**VContainer 公式**
- 公式サイト: https://vcontainer.hadashikick.jp/
- GitHub: https://github.com/hadashiA/VContainer
- パッケージ: `"jp.hadashikick.vcontainer": "https://github.com/hadashiA/VContainer.git?path=VContainer/Assets/VContainer#1.16.9"`

**学習リソース**
- Hello Worldガイド: https://vcontainer.hadashikick.jp/getting-started/hello-world
- LifetimeScope設計: https://vcontainer.hadashikick.jp/scoping/lifetime-overview
- 最適化ガイド: https://vcontainer.hadashikick.jp/optimization/codegen

**コミュニティ記事**
- [UnityのDI超ざっくり入門 3 - VContainerを使ってみる](https://zenn.dev/qemel/articles/14d247b9945527)
- [VContainer入門(2) - LifetimeScope](https://qiita.com/sakano/items/e38306a8204c531a40c1)

### 8.4 技術スタック比較

| 項目 | VContainer | Zenject | 手動DI |
|------|------------|---------|---------|
| パフォーマンス | ★★★★★ | ★★★☆☆ | ★★★★★ |
| 学習コスト | ★★★☆☆ | ★★☆☆☆ | ★★★★☆ |
| 機能豊富さ | ★★★★☆ | ★★★★★ | ★★☆☆☆ |
| コミュニティ | ★★★☆☆ | ★★★★☆ | ★★★★★ |
| 保守性 | ★★★★★ | ★★★★☆ | ★★☆☆☆ |

**推奨使用場面**:
- **VContainer**: 新規プロジェクト、パフォーマンス重視、モダンな設計
- **Zenject**: 既存の大規模プロジェクト、豊富な機能が必要
- **手動DI**: プロトタイプ、小規模プロジェクト、学習目的

---

## まとめ

このガイドは、ジェリー農場ゲームの実装例を基に、VContainerを使った実践的な設計パターンをまとめました。重要なポイント：

1. **明確な階層構造**: App→Scene→UI→Unitの4層構造
2. **責任の分離**: Model/View/Presenter+Systemの役割分担
3. **実装パターン**: 3つのPresenterパターンの使い分け
4. **判断基準**: 各コンポーネントをどこに配置するかの明確な基準
5. **実践的なコード例**: 実際のゲームプロジェクトからの抜粋

新機能実装時は、必ず「責任の分析→配置先決定→依存関係確認→Dispose管理」の順序で進めることで、保守性の高いコードを維持できます。

参考リポジトリとコード例を活用して、チーム全体でのVContainer習得を効率的に進めてください。