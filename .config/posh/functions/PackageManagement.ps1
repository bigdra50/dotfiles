# PackageManagement.ps1
# パッケージとモジュール管理関数の実装

Write-ProfileLog "パッケージ管理関数を読み込みます" "Info"

# 不足しているパッケージをインストールする関数
function Install-PackageIfMissing {
    param (
        [string]$PackageName
    )
    
    Write-ProfileLog "パッケージを確認します: $PackageName" "Debug"
    
    # wingetコマンドを使用してパッケージのインストール状態を確認
    # 出力を文字列として取得し、パッケージ名が含まれているかチェック
    $installed = winget list --id $PackageName -e | Out-String
    
    if (-not $installed.Contains($PackageName)) {
        # パッケージがインストールされていない場合は、インストールを実行
        # 警告レベルでログを記録し、ユーザーに通知する
        Write-ProfileLog "パッケージをインストールします: $PackageName" "Warning"
        winget install --id $PackageName -e --source winget
    } else {
        # パッケージが既にインストールされている場合はデバッグログのみ記録
        Write-ProfileLog "パッケージは既にインストールされています: $PackageName" "Debug"
    }
}

# 不足しているPowerShellモジュールをインストールする関数
function Install-ModuleIfMissing {
    param (
        [string]$ModuleName
    )
    
    Write-ProfileLog "モジュールを確認します: $ModuleName" "Debug"
    
    # PowerShellモジュールのインストール状態を確認
    # Get-Module -ListAvailableはインストール済みのすべてのモジュールを返す
    if (-not (Get-Module -ListAvailable -Name $ModuleName)) {
        # モジュールがインストールされていない場合は、インストールを実行
        # CurrentUserスコープでインストールし、プロンプトを強制的に無視
        Write-ProfileLog "モジュールをインストールします: $ModuleName" "Warning"
        Install-Module -Name $ModuleName -Scope CurrentUser -Force
    } else {
        # モジュールが既にインストールされている場合はデバッグログのみ記録
        Write-ProfileLog "モジュールは既にインストールされています: $ModuleName" "Debug"
    }
}

# 依存関係の更新を手動で実行する関数
function Update-OhMyPoshDependencies {
    # チェックフラグを削除して再インストールチェックを強制する
    if (Test-Path $script:ompCheckFlag) {
        Remove-Item $script:ompCheckFlag -Force
    }
    
    Write-Host "Oh My Poshインストールチェックを実行しています..." -ForegroundColor Cyan
    Write-ProfileLog "手動でOh My Poshインストールチェックを実行します" "Warning"
    
    # Oh My Posh本体のチェック
    try {
        Install-PackageIfMissing -PackageName 'JanDeDobbeleer.OhMyPosh'
        Write-Host "Oh My Poshパッケージを確認しました" -ForegroundColor Green
    } catch {
        Write-Host "Oh My Poshのインストール中にエラーが発生しました: $($_.Exception.Message)" -ForegroundColor Red
        Write-ProfileLog "Oh My Poshのインストール中にエラーが発生しました: $($_.Exception.Message)" "Error"
    }
    
    # 依存モジュールのチェック
    # これらのモジュールは設定ファイルで使用されるため必須
    $modules = @('posh-git', 'PSFzf', 'PSEverything', 'ZLocation')
    foreach ($moduleName in $modules) {
        try {
            Install-ModuleIfMissing -ModuleName $moduleName
            Write-Host "$moduleName モジュールを確認しました" -ForegroundColor Green
        } catch {
            Write-Host "$moduleName のインストール中にエラーが発生しました: $($_.Exception.Message)" -ForegroundColor Red
            Write-ProfileLog "$moduleName のインストール中にエラーが発生しました: $($_.Exception.Message)" "Error"
        }
    }
    
    # チェックフラグを再作成
    "Oh My Poshインストールチェックが完了しました: $(Get-Date)" | Out-File -FilePath $script:ompCheckFlag
    Write-Host "依存関係の更新が完了しました" -ForegroundColor Green
    Write-ProfileLog "依存関係の更新が完了しました" "Success"
}

Write-ProfileLog "パッケージ管理関数の読み込みが完了しました" "Success"
