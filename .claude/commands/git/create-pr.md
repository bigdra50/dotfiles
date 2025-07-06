PRを作成するコマンド。textlintが利用可能な場合は、PR内容を必ずlintでチェックする。

Follow these rules:

1. **textlintチェックの実行（利用可能な場合）**
   - まず `which textlint` または `command -v textlint` でtextlintの存在確認
   - 利用可能な場合、PR説明文やコミットメッセージをlintでチェック
   - lintエラーがある場合は修正してからPR作成を続行

2. **Git状態の確認**
   - `git status` で現在のブランチと変更状況を確認
   - `git diff` でステージされていない変更を確認
   - `git diff --staged` でステージされた変更を確認

3. **コミットの実行（必要に応じて）**
   - 未コミットの変更がある場合、gitmoji形式でコミット
   - コミットメッセージは日本語で記述
   - "Generated with Claude Code" フッターは含めない

4. **ブランチのプッシュ**
   - リモートにプッシュされていない変更がある場合、プッシュを実行
   - 初回プッシュの場合は `-u` フラグを使用

5. **PR作成**
   - `gh pr create` コマンドでPR作成
   - PRタイトルとボディを自動生成
   - 変更内容を分析してわかりやすい説明を作成

Workflow:
1. textlintの存在確認とlintチェック実行（利用可能な場合）
2. Git状態の確認（`git status`, `git diff`, `git diff --staged`）
3. 未コミット変更の分析とコミット実行
4. ブランチの存在確認とリモートプッシュ
5. PR内容の生成（タイトル、要約、テスト計画）
6. GitHub PRの作成（`gh pr create`）
7. 作成されたPR URLの表示

If $ARGUMENTS is provided, use it as additional context for the PR title and description.

エラーハンドリング:
- Gitリポジトリでない場合は適切なエラーメッセージを表示
- GitHub CLIが利用できない場合は設定方法を案内
- textlintエラーがある場合は修正を促してから続行
- ネットワークエラーやGitHub APIエラーの適切な処理