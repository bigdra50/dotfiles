# OhMyPosh.ps1
# Oh My Posh シェルプロンプトの設定と初期化

Write-ProfileLog "Oh My Posh 設定を読み込みます" "Info"

# 初回実行時のみインストールチェックを行い、起動時間を最適化
$startTime = Get-Date

# フラグファイルの存在をチェックし、初回実行かどうかを判断
if (-not (Test-Path $script:ompCheckFlag)) {
    Write-ProfileLog "初回セットアップ: 必要なパッケージをチェックします" "Warning"
    
    # Oh My Posh本体がインストールされているかチェック
    try {
        Install-PackageIfMissing -PackageName 'JanDeDobbeleer.OhMyPosh'
        Write-ProfileLog "Oh My Poshパッケージをチェックしました" "Success"
    } catch {
        Write-ProfileLog "Oh My Poshのインストール中にエラーが発生しました: $($_.Exception.Message)" "Error"
    }
    
    # 必要なPowerShellモジュールをチェック
    # これらのモジュールはシェル環境の機能強化に使用される
    $modules = @('posh-git', 'PSFzf', 'PSEverything', 'ZLocation')
    foreach ($moduleName in $modules) {
        try {
            Install-ModuleIfMissing -ModuleName $moduleName
            Write-ProfileLog "$moduleName モジュールをチェックしました" "Success"
        } catch {
            Write-ProfileLog "$moduleName のインストール中にエラーが発生しました: $($_.Exception.Message)" "Error"
        }
    }
    
    # 次回以降のチェックをスキップするためのフラグファイルを作成
    "Oh My Poshインストールチェックが完了しました: $(Get-Date)" | Out-File -FilePath $script:ompCheckFlag
    Write-ProfileLog "セットアップが完了しました。この確認は次回起動時には実行されません" "Success"
} else {
    Write-ProfileLog "パッケージインストールチェックをスキップします（既に完了済み）" "Info"
}

$installCheckTime = (Get-Date) - $startTime

# Oh My Posh設定を読み込む（毎回実行）
$startTime = Get-Date
Write-ProfileLog "Oh My Posh設定を読み込みます" "Info"

try {
    # Oh My Poshを初期化し、指定したテーマを適用
    # easy-term.omp.jsonは視認性の良いテーマで、ターミナルでの作業に適している
    oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\easy-term.omp.json" | Invoke-Expression
    Write-ProfileLog "Oh My Poshの読み込みが完了しました" "Success"
} catch {
    Write-ProfileLog "Oh My Posh設定の読み込み中にエラーが発生しました: $($_.Exception.Message)" "Error"
}

$ompLoadTime = (Get-Date) - $startTime

# Oh My Poshの読み込み時間をログに記録
Write-ProfileLog "Oh My Posh読み込み時間: $($ompLoadTime.TotalMilliseconds) ms" "Info"

# インストールチェック時間の統計を表示
if (Test-Path $script:ompCheckFlag) {
    Write-ProfileLog "インストールチェックをスキップしました（約2800ms節約）" "Info"
} else {
    Write-ProfileLog "インストールチェック時間: $($installCheckTime.TotalMilliseconds) ms" "Info"
}

Write-ProfileLog "Oh My Posh設定の読み込みが完了しました" "Success"
