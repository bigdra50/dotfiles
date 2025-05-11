# Environment.ps1
# 環境変数とシステム設定の実装

Write-ProfileLog "環境変数と実行ポリシーを設定します" "Info"

# 実行ポリシーの設定
# スクリプトの実行を許可するため、現在のユーザーの実行ポリシーを変更
# カスタムスクリプトを実行するために必要
Write-ProfileLog "実行ポリシーを設定します" "Info"
Set-ExecutionPolicy -Scope "CurrentUser" -ExecutionPolicy "Unrestricted"
Write-ProfileLog "実行ポリシーを設定しました" "Success"

# 環境変数の設定
Write-ProfileLog "環境変数を設定します" "Info"

# XDG設定ホームディレクトリ（Unix/Linux互換）
# クロスプラットフォームの設定ファイルの格納場所として使用
$env:XDG_CONFIG_HOME = "$HOME/.config"

# デフォルトエディタをNeovimに設定
# 様々なツールで使用されるデフォルトエディタを統一
$env:EDITOR = 'nvim'

# PATHに各種ツールのディレクトリを追加
# rye（Python環境管理ツール）
AddPathToEnv $env:USERPROFILE\.rye\shims

# Go言語のバイナリディレクトリ
AddPathToEnv $env:USERPROFILE\go\bin

# .NET Coreツールのディレクトリ
AddPathToEnv $env:USERPROFILE\.dotnet\tools

Write-ProfileLog "環境変数の設定が完了しました" "Success"
