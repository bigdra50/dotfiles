現在のブランチの**プッシュ済み内容**でPRを作成するコマンド。未コミット変更は無視し、既存のコミット履歴のみを対象とします。

Follow these rules:

1. **Git状態の確認**

   - `git status` で現在のブランチを確認
   - `git log main..HEAD --oneline` でメインブランチからの差分コミットを表示
   - `git diff main...HEAD --name-only` で変更ファイル一覧を確認

2. **プッシュ状況の確認**

   - `git status` でリモートとの同期状況を確認
   - 未プッシュのコミットがある場合は警告を表示（PRは作成しない）

3. **PR作成の前提条件チェック**

   - 現在のブランチがmain以外であることを確認
   - リモートブランチが存在し、最新の状態であることを確認
   - メインブランチとの差分があることを確認

4. **PR内容の生成**

   - プッシュ済みコミット履歴から変更内容を分析
   - 変更ファイルからPRタイトルとボディを自動生成
   - 技術的詳細とレビューポイントを含める

5. **GitHub PR作成**
   - `gh pr create` コマンドでPR作成
   - 作成されたPR URLを表示

Workflow:

1. Git状態の確認（`git status`, `git log main..HEAD`, `git diff main...HEAD --name-only`）
2. プッシュ状況の確認（未プッシュコミットの有無チェック）
3. PR作成可能性の判定（ブランチ、リモート状況、差分の確認）
4. プッシュ済み内容の分析（コミット履歴、変更ファイル）
5. PR内容の生成（タイトル、概要、技術詳細、レビューポイント）
6. GitHub PRの作成（`gh pr create`）
7. 作成されたPR URLの表示

If $ARGUMENTS is provided, use it as additional context for the PR title and description.

エラーハンドリング:

- Gitリポジトリでない場合は適切なエラーメッセージを表示
- GitHub CLIが利用できない場合は設定方法を案内
- 未プッシュコミットがある場合は先にプッシュするよう案内
- mainブランチにいる場合はfeatureブランチ作成を案内
- メインブランチとの差分がない場合は適切なメッセージを表示
- ネットワークエラーやGitHub APIエラーの適切な処理

重要な制約:

- 未コミット変更は一切処理しない（git addやgit commitは実行しない）
- 未プッシュコミットがある場合はPR作成を中止する
- プッシュ済みの内容のみでPRを作成する
- PRの文章は､ @../../docs/documentation/anti-ai-writing.md に従って作成する

