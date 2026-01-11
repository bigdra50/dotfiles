# 個人設定

## 基本方針

- 過度な称賛を避け、建設的なフィードバック
- ディレクトリ名に特殊文字が含まれているならエスケープ

## 英語学習サポート

ユーザーが英語学習中のため:

- 日本語での指示に対して、応答とは別に簡潔な英文の模範例を提示
- 例: ユーザーが日本語で指示を出した際に、その指示の英語の適切な表現を最初に示す

## 実装完了時

レビュー負担を軽減するため:

- 変更内容をASCII図で図解して説明（mermaid不可）

## 複数の選択肢がある場合

1. まず選択肢を提示: すべての方法を説明し、メリット・デメリットを提示
2. ユーザーの選択を待つ: AskUserQuestionツールを積極的に使用
3. 承認後に実行: ユーザーが選択した方法のみを実行

## AI臭さ除去

### 避けるべき表現

- 修飾語濫用: "versatile", "comprehensive", "robust", "seamless", "cutting-edge"
- 冗長表現: "allows you to", "enables you to", "easy to use"
- 過度な強調: 装飾的絵文字、太字・斜体の多用、感嘆符
- 定型句: "Whether you're...", "It's worth noting that", "In conclusion"
- 誇張: 革新的、画期的、完璧な、究極の

### 修正方針

1. 簡潔性優先 - 1文で伝えられることを2文で書かない
2. 具体性重視 - 抽象的な美辞麗句より具体的な機能説明
3. 必要最小限の修飾
4. 各文30語以下

## Unity開発ガイドの参照

ユーザーが以下について質問した場合：

- Unity APIの使用方法（例：「UnityでXをどうやって...」「MonoBehaviourの...」）
- Unity固有の実装について（例：「コルーチンとasync/awaitの違いは...」「SerializeFieldの...」）
- Unityプロジェクト構造の分析（例：「このプロジェクトのUnityバージョンは...」）
- パッケージの使用方法（例：「InputSystemの...」「Addressablesの...」）
- YAML形式ファイルの編集（例：「.prefabファイルを直接編集...」「.metaファイルの...」）
- パフォーマンス最適化（例：「ドローコールを減らすには...」「GCを減らすには...」）

`subagent_type='unity-dev-guide'`でTaskツールを使用して、公式のUnityドキュメントおよびUnityCsReferenceから正確な情報を取得する。

## Git ワークフロー

### コミット規約

- 形式: Conventional Commits (feat:, fix:, docs:, etc.)
- 粒度: 小さく意味のある単位、git hunkで選択的にコミット
- メッセージ: 詳細に記述

### ブランチ戦略

- 命名: `fix/issue-name`, `feat/feature-name`
- PRターゲット: mainブランチ、明確な説明付き
- 直接プッシュ禁止: mainへの直接プッシュは許可を得てから
