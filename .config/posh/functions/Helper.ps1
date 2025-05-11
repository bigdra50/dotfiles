# Helper.ps1
# ヘルパー関数の実装

Write-ProfileLog "ヘルパー関数を読み込みます" "Info"

# Vimの設定ファイルを編集する関数
function EditVimRc { 
    # Neovimを使用して.vimrcを開く
    # エディタ設定を簡単に編集できるようにするショートカット
    nvim $UserProfile\.config\nvim\init.vim 
}

# 環境変数PATHに新しいパスを追加する関数
function AddPathToEnv {
    param (
        [string]$Path
    )
    
    Write-ProfileLog "$Path をPATHに追加します" "Debug"
    
    # PATH環境変数が存在しない場合（ほぼありえないが安全のため）は新規作成
    if (-not (Test-Path Env:Path)) {
        $env:Path = $Path
    } else {
        # 既存のPATHに新しいパスを追加（セミコロン区切り）
        $env:Path += ";$Path"
    }
}

# 管理者権限でPowerShellを起動する関数
function CustomSudo { 
    # 現在のPowerShellセッションと同じシェルで管理者権限のウィンドウを開く
    # これにより、管理者権限が必要な操作をスムーズに実行できる
    Start-Process powershell.exe -Verb runas 
}

# Hostsファイルを管理者権限で開く関数
function CustomHosts { 
    # Windowsのhostsファイルを編集するショートカット
    # ローカル開発環境の設定などに便利
    start notepad C:\Windows\System32\drivers\etc\hosts -verb runas 
}

# Windows Updateの設定画面を開く関数
function CustomUpdate { 
    # Windows Updateの設定画面を直接開くショートカット
    explorer ms-settings:windowsupdate 
}

# ghqを使用してリポジトリに移動する関数
function ToGhqList {
    # fuzzy finderを使用してghq管理下のリポジトリを選択し、そのディレクトリに移動する
    # 多数のリポジトリを効率的に管理するために使用
    pushd "$(ghq root)\$(ghq list --vcs=git | fzf)"
}

# ghqリポジトリに簡単に移動するためのショートカット
function q {
    # fuzzy finderを使用してghq管理下のリポジトリを選択し、そのディレクトリに移動する
    # ToGhqListと似ているが、より短いコマンド名で呼び出せる
    pushd $(ghq list -p | fzf)
}

# 現在のパスを取得する関数
function GetCurrentPath {
    # 現在のディレクトリの絶対パスを取得して表示
    Convert-Path .
}

# ホームディレクトリのパスを～に置き換えて表示する関数
function ReplaceHomePathNameToChilda {
    # 現在のパスを取得
    $curPath = $ExecutionContext.SessionState.Path.CurrentLocation.Path
    
    # パスがホームディレクトリから始まる場合は～に置き換える
    # これにより、長いホームディレクトリパスを簡潔に表示できる
    if ($curPath.ToLower().StartsWith($HOME.ToLower())) {
        $curPath = "~" + $curPath.SubString($HOME.Length)
    }
    
    # 変換後のパスを緑色で表示
    Write-Host $curPath -ForegroundColor Green
}

# Oh My Posh用のpwsh10kテーマをダウンロードする関数
function Load10kConfig {
    # pwsh10k設定ファイルのパス
    $pwsh10kConfigPath = "$HOME/pwsh10k.omp.json"
    
    # 設定ファイルが存在しない場合はダウンロード
    if (-not (Test-Path $pwsh10kConfigPath)) {
        $pwsh10kConfigUrl = "https://raw.githubusercontent.com/Kudostoy0u/pwsh10k/master/pwsh10k.omp.json"
        Invoke-WebRequest -Uri $pwsh10kConfigUrl -OutFile $pwsh10kConfigPath
    }
}

Write-ProfileLog "ヘルパー関数の読み込みが完了しました" "Success"
