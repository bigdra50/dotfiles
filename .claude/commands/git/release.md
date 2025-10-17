# git-release

Git tagを作成し、GitHub Releasesを公開してリモートにpushする統合リリースコマンド

## ワークフロー:

1. **事前確認**
   - `git status` で未コミット変更がないことを確認
   - `git fetch --tags` で既存のtagを取得
   - 現在のブランチがmainまたはmasterであることを確認

2. **バージョン決定**
   - 最新のtagを確認して次のバージョンを提案
   - セマンティックバージョニング（major.minor.patch）に従う
   - ユーザーからバージョン番号を取得（例: v1.0.0）

3. **リリースノート生成**
   - 前回のtagからの変更履歴を自動取得
   - `git log --pretty=format:"- %s" [前回tag]..HEAD`
   - 必要に応じてユーザーが編集

4. **Tag作成とRelease公開**
   - `git tag -a [version] -m "[release message]"` でアノテートタグ作成
   - `git push origin [version]` でtagをpush
   - `gh release create [version] --title "[title]" --notes "[notes]"` でGitHub Release作成
   - プレリリースオプションの確認（--prerelease）

5. **結果確認**
   - 作成されたReleaseのURLを表示
   - `gh release view [version]` で詳細確認
   - ローカルとリモートのtag同期を確認

## エラーハンドリング:
- 未コミットの変更が存在する場合: コミットまたはstashを促す
- mainブランチ以外での実行: ブランチ切り替えを提案
- 同じバージョンのtagが既に存在: 別のバージョン番号を要求
- GitHub CLI未インストール: インストール方法を案内
- リモートリポジトリとの接続エラー: ネットワーク確認を促す
- GitHub認証エラー: `gh auth login` の実行を案内

## 引数オプション:
- `$ARGUMENTS`: バージョン番号（省略時は対話形式で決定）
  - 例: `v1.2.3`, `v2.0.0-beta.1`

## 使用例:
```bash
# 対話形式でリリース作成
claude /git-release

# バージョン指定でリリース作成
claude /git-release v1.2.0

# プレリリース版の作成
claude /git-release v1.2.0-beta.1
```

## 前提条件:
- GitHub CLIがインストール済み（`gh`コマンド）
- GitHub認証が完了済み（`gh auth status`で確認）
- リモートリポジトリがGitHubにホストされている
- main/masterブランチへのpush権限がある

## セマンティックバージョニングガイド:
- **Major (X.0.0)**: 破壊的変更を含む
- **Minor (0.X.0)**: 後方互換性のある機能追加
- **Patch (0.0.X)**: 後方互換性のあるバグ修正
- **Pre-release**: `-alpha`, `-beta`, `-rc` などのサフィックス

## 補足:
- リリースノートは自動生成後に編集可能
- ドラフトリリースを作成する場合は `--draft` オプションを使用
- アセットファイルの添付が必要な場合は作成後に手動で追加