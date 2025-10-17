# create-shader

指定された要件に基づいて、Unity URP用のシェーダーを自動生成します。Agent/Agent.mdで定義されている6ステップのプロセスに従い、柔軟にシェーダーを作成します。

## ワークフロー:

1. **要件の解析と確認**
   - 自然言語で記述された要件を解析
   - シェーダーの種類と目的を推定
   - 不明な点は対話的に確認

2. **詳細仕様の収集**
   - 視覚的要件の詳細化
   - 必要なプロパティの定義
   - 技術的要件（描画順、カリング等）の確認

3. **シェーダー生成**
   - デフォルトでHLSLPROGRAMを使用
   - 必要に応じてテンプレート（PerlinNoise、Random）を自動適用
   - URPに準拠した実装

4. **ファイル出力と確認**
   - 生成コードのプレビュー
   - 指定ディレクトリへの保存
   - Unity Editorでの確認方法の提示

## 基本的な使い方:

```bash
# 自然言語で要件を指定
claude /create-shader "水面の揺れを表現するシェーダー"

# ファイル名を指定
claude /create-shader "ホログラムエフェクト" --name HologramShader

# CGPROGRAMを使用
claude /create-shader "トゥーンシェーディング" --cg

# 非対話モードで詳細指定
claude /create-shader "金属的な光沢" --name MetallicShader --properties '{"_Metallic": {"type": "Range(0,1)", "default": 0.5}}' --no-interactive
```

## オプション詳細:

- `--name, -n`: 出力ファイル名（拡張子なし）
- `--cg`: CGPROGRAMで実装（デフォルトはHLSLPROGRAM）
- `--output-dir, -o`: 出力ディレクトリ（デフォルト: ShaderProject/Assets/upft/GraphicsAssets/Shader/）
- `--no-interactive`: 非対話モード
- `--properties, -p`: Inspectorプロパティの事前定義（JSON形式）
- `--lighting`: ライティングモデル（lit/unlit/custom）
- `--render-queue`: レンダーキュー（Opaque/Transparent/AlphaTest）

## 自動判定と対話:

要件から以下を自動的に判定し、必要に応じて確認します：
- シェーダーの種類（Lit/Unlit/Post-processing等）
- 必要なテンプレート（ノイズ、アニメーション等のキーワードから）
- 透明度の有無（透明、ガラス等のキーワードから）
- 描画順序（透明度やエフェクトタイプから）

## テンプレート自動適用:

以下のキーワードを検出すると、自動的にテンプレートを適用：
- ノイズ、揺れ、波 → PerlinNoise.md
- ランダム、乱数 → Random.md
- 時間、アニメーション → _Time変数の使用

## エラーハンドリング:

- 要件が不明確な場合の対話的な詳細化
- 既存ファイルの上書き確認
- テンプレートファイルの存在確認
- Unity/URPバージョンの互換性確認

## 使用例:

```bash
# シンプルな要件
claude /create-shader "水のシェーダー"

# 詳細な要件
claude /create-shader "リアルタイムで変化する雲のような煙エフェクト、半透明で光が透過する"

# オプション組み合わせ
claude /create-shader "レトロゲーム風のピクセルシェーダー" --name RetroPixel --render-queue Transparent

# プロパティ事前定義
claude /create-shader "調整可能なアウトライン" --properties '{"_OutlineWidth": {"type": "Float", "default": 0.1}, "_OutlineColor": {"type": "Color", "default": "(0,0,0,1)"}}'
```

## 実装の詳細:

1. 要件文字列を解析して、シェーダーの目的と特徴を抽出
2. Agent/Agent.mdの6ステップに従って必要な情報を収集
3. 適切なテンプレートとURPマクロを使用してシェーダーコードを生成
4. 生成されたシェーダーをプレビュー表示し、確認後にファイル保存

$ARGUMENTSで要件を受け取り、必要に応じて対話的に詳細を確認しながら、柔軟にシェーダーを生成します。