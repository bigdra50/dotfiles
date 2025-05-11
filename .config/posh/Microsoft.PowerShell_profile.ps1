# メインプロファイル - $PROFILE
# 機能ごとに分割したスクリプトを読み込むメインファイル

# グローバル変数
$script:IsDebug = $env:PWSH_DEBUG -eq "true"
$script:LogFile = "$HOME/.pwsh-profile.log"
$script:ompCheckFlag = "$HOME/.omp_installed"
$script:FunctionsPath = "$(Split-Path -Parent $PROFILE)/functions"

# 機能モジュールのディレクトリ作成を確認
if (-not (Test-Path $script:FunctionsPath)) {
    # ディレクトリが存在しない場合は作成
    New-Item -Path $script:FunctionsPath -ItemType Directory -Force | Out-Null
}

# ロギング関数を最初に読み込む
. "$script:FunctionsPath/Logging.ps1"

# プロファイル初期化ログの開始
Write-ProfileLog "プロファイル初期化を開始します" "Info"
if ($script:IsDebug) {
    Write-ProfileLog "デバッグモードが有効です" "Debug"
}

# 各機能モジュールを読み込む
$modules = @(
    "Utility.ps1",          # ユーティリティ関数
    "PackageManagement.ps1", # パッケージ管理関数
    "Helper.ps1",            # ヘルパー関数
    "ArgumentCompleters.ps1", # 引数補完関数
    "Environment.ps1",       # 環境変数設定
    "OhMyPosh.ps1",          # Oh My Posh 設定
    "PSReadLine.ps1",        # PSReadLine 設定
    "Aliases.ps1"            # エイリアス設定
)

# 各モジュールを読み込む
foreach ($module in $modules) {
    $modulePath = "$script:FunctionsPath/$module"
    if (Test-Path $modulePath) {
        Write-ProfileLog "モジュールを読み込みます: $module" "Info"
        . $modulePath
        Write-ProfileLog "モジュールの読み込みが完了しました: $module" "Success"
    } else {
        Write-ProfileLog "モジュールが見つかりません: $module (これは初回実行時には正常な状態です)" "Warning"
    }
}

# ローカル環境の読み込み
Write-ProfileLog "ローカル環境設定を読み込みます" "Info"
try {
    if (Test-Path ~/.pwshenv.local.ps1) {
        . ~/.pwshenv.local.ps1
        Write-ProfileLog "ローカル環境の読み込みが完了しました" "Success"
    } else {
        Write-ProfileLog "~/.pwshenv.local.ps1 が見つかりません、スキップします" "Warning"
    }
} catch {
    Write-ProfileLog "ローカル環境の読み込み中にエラーが発生しました: $($_.Exception.Message)" "Error"
}

# プロファイル完了
Write-ProfileLog "プロファイル初期化が完了しました" "Success"

# デバッグモード時のみ基本情報を表示
if ($script:IsDebug) {
    Write-Host "プロファイルが読み込まれました" -ForegroundColor Green
    Write-Host "ログファイル: $script:LogFile" -ForegroundColor Cyan
    Write-Host "利用可能なコマンド: Update-OhMyPoshDependencies, Show-ProfileLog, Clear-ProfileLog" -ForegroundColor Yellow
}
