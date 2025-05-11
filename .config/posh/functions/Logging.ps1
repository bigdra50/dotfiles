# Logging.ps1
# ログ機能の実装

# ログ関数 - 一貫性のあるログ形式と条件付き表示のための関数
function Write-ProfileLog {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,
        
        [Parameter(Position = 1)]
        [ValidateSet("Info", "Warning", "Error", "Debug", "Success")]
        [string]$Level = "Info"
    )
    
    # タイムスタンプをミリ秒単位で記録することで、
    # パフォーマンス分析やプロファイル読み込みの問題解決が容易になる
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # 常にログファイルに記録
    Add-Content -Path $script:LogFile -Value $logMessage -Encoding UTF8
    
    # コンソール出力の色を設定
    $foregroundColor = switch ($Level) {
        "Info"    { "Cyan" }
        "Warning" { "Yellow" }
        "Error"   { "Red" }
        "Debug"   { "Magenta" }
        "Success" { "Green" }
        default   { "White" }
    }
    
    # レベルとデバッグモードに基づいてメッセージを表示
    $shouldDisplay = switch ($Level) {
        # 警告とエラーは常に表示する（重要度が高いため）
        "Warning" { $true }
        "Error"   { $true }
        # その他のメッセージはデバッグモード時のみ表示
        default   { $script:IsDebug }
    }
    
    if ($shouldDisplay) {
        Write-Host $logMessage -ForegroundColor $foregroundColor
    }
}

# ログファイル表示関数
function Show-ProfileLog {
    param (
        [int]$Last = 50,  # デフォルトでは最新50行のみ表示
        [switch]$All      # すべてのログを表示するオプション
    )
    
    if (Test-Path $script:LogFile) {
        if ($All) {
            Get-Content $script:LogFile | Out-Host
        } else {
            Get-Content $script:LogFile -Tail $Last | Out-Host
        }
    } else {
        Write-Host "ログファイルが見つかりません: $script:LogFile" -ForegroundColor Red
    }
}

# ログファイルクリア関数
function Clear-ProfileLog {
    if (Test-Path $script:LogFile) {
        # ファイルを削除して新しく作成し直す
        Remove-Item $script:LogFile -Force
        New-Item $script:LogFile -ItemType File | Out-Null
        Write-Host "プロファイルログをクリアしました" -ForegroundColor Green
    } else {
        Write-Host "ログファイルが見つかりません: $script:LogFile" -ForegroundColor Yellow
    }
}
