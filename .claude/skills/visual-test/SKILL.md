---
name: visual-test
description: |
  スナップショットテスト結果とFigmaデザインをビジュアル比較。
  Claudeの画像認識でスクリーンショットとFigma PNGを見比べ、ノードプロパティの差分も検出する。
  Use for: "ビジュアルテスト", "デザイン比較", "Figma比較", "見た目テスト", "visual test"
allowed-tools: Read, Glob, Grep, Bash
user-invocable: true
---

# Visual Test - Figma Design Compliance Check

スナップショットテスト結果をFigmaデザインと比較し、視覚的差異を検出する。
Claudeの画像認識 + ノードプロパティ差分の2層で検証する。

## Usage

```
/visual-test                # 最新スナップショットの全パネルを比較
/visual-test menu           # メニューパネルのみ
/visual-test calibration    # キャリブレーションのみ
/visual-test <snapshot-dir> # 特定のスナップショットディレクトリを指定
```

## Execution

### Step 1: マッピング読み込み

プロジェクトの `.claude/reference/visual-test-mapping.md` を Read で読む。
このファイルにパネルごとのFigma画像ファイル名、フレームJSONファイル名、USSファイルパス、チェック対象プロパティが定義されている。

ファイルが見つからない場合はユーザーに作成を促す。

### Step 2: 最新スナップショット特定

```bash
ls -td test-artifacts/snapshots/**/*/ 2>/dev/null | head -1
```

引数でディレクトリが指定されている場合はそれを使用。
スナップショットがない場合: 「スナップショットを先に取得してください」と案内。

### Step 3: 対象パネルの決定

引数でパネル名が指定されていればそれだけ、なければマッピングの全パネルを対象にする。

### Step 4: 各パネルの比較（パネルごとに実行）

#### 4a. ビジュアル比較（Claudeの目視）

1. Read tool でスナップショットの `screenshot.png` を読む（画像として認識される）
2. Read tool で `docs/figma/images/{対応する画像}.png` を読む
3. 2つの画像を見比べて以下を確認:

チェック項目:
- 枠線（border）の有無・色・太さ
- 背景色
- テキストサイズ・ウェイト・配置
- 要素間スペーシング
- 角丸（border-radius）
- 全体レイアウト・配置
- アイコン・チェックマークの有無
- 要素の表示/非表示

#### 4b. ノードプロパティ差分

マッピングに定義されたチェック対象について:

1. Read で `docs/figma/frames/{対応するフレーム}.json` を読み、該当ノードのプロパティを抽出
2. Read で対応する USS ファイルの該当クラスを読む
3. 以下のプロパティを比較:
   - `border` / `border-width` / `border-color` ← JSON の `strokes` / `strokeWeight`
   - `background` / `background-color` ← JSON の `fills`
   - `border-radius` ← JSON の `cornerRadius`
   - `font-size` / `font-weight` ← JSON の `style` (テキストノード)
   - `padding` / `margin` ← JSON の `paddingLeft` 等
   - `color` ← JSON の `fills` (テキストノード)

#### 4c. resolvedStyle 検証（inspect_*.json がある場合）

スナップショットディレクトリの `inspect_*.json` を Read し、resolvedStyle の実際の値を確認する。

### Step 5: レポート出力

```markdown
# Visual Test Report: {snapshot_dir}

## Summary
| パネル | ビジュアル | プロパティ差分 | 状態 |
|--------|----------|--------------|------|
| Menu   | 2件      | 3件          | NG   |
| Calibration | -   | -            | OK   |
| ...    |          |              |      |

## {Panel Name}

### ビジュアル差異
| # | 要素 | Figma | 実装 | 重要度 |
|---|------|-------|------|--------|
| 1 | scenario button | border 4px あり | border なし | High |

### ノードプロパティ差分
| 要素 | プロパティ | Figma JSON | USS | 状態 |
|------|----------|-----------|-----|------|
| .scenario-item | border-width | strokeWeight: 4 | (未定義) | MISSING |

### resolvedStyle
| 要素 | プロパティ | 期待値 | 実際値 | 状態 |
|------|----------|-------|-------|------|

---
(各パネル繰り返し)
```

## Notes

- Figma 画面構成が変わった場合は `.claude/reference/visual-test-mapping.md` を更新する
- `docs/figma/frames/*.json` は Figma REST API から取得したノード構造。色は `fills[].color`、角丸は `cornerRadius`、ストロークは `strokes` + `strokeWeight`
- USS は Unity StyleSheet。CSS類似だが `-unity-*` プレフィックスのプロパティがある
- 3D シーン部分（背景のアイソレーターモック等）はUIテスト対象外。UI Toolkit で描画されるパネル要素のみ比較する
