# ------------------- functions ---------------------
# Utilities 

function unity-version {
    (Get-Content .\ProjectSettings\ProjectVersion.txt | Select-String "m_EditorVersion:" | %{$($_-split(" "))[1]})
}

function uadb {
    & "~\opt\unity\$(unity-version)\Editor\Data\PlaybackEngines\AndroidPlayer\SDK\platform-tools\adb.exe" @args
}

function ls-empty-dirs{
    Get-ChildItem -Directory | Where-Object { -not (Get-ChildItem $_) } | Select-Object -ExpandProperty FullName
}
# ------------------ package management ------------------


function Install-PackageIfMissing {
    param (
        [string]$PackageName
    )
    $installed = winget list --id $PackageName -e | Out-String
    if (-not $installed.Contains($PackageName)) {
        winget install --id $PackageName -e --source winget
    }
}


function Install-ModuleIfMissing {
    param (
        [string]$ModuleName
    )
    if (-not (Get-Module -ListAvailable -Name $ModuleName)) {
        Install-Module -Name $ModuleName -Scope CurrentUser -Force
    }
}

# ------------------ package management ------------------


function EditVimRc { nvim $UserProfile\.config\nvim\init.vim }
function AddPathToEnv {
    param (
        [string]$Path
    )
    if (-not (Test-Path Env:Path)) {
        $env:Path = $Path
    } else {
        $env:Path += ";$Path"
    }
}

function CustomListChildItems { Get-ChildItem $args[0] -force | Sort-Object -Property @{ Expression = 'LastWriteTime'; Descending = $true }, @{ Expression = 'Name'; Ascending = $true } | Format-Table -AutoSize -Property Mode, Length, LastWriteTime, Name }
function CustomSudo { Start-Process powershell.exe -Verb runas }
function CustomHosts { start notepad C:\Windows\System32\drivers\etc\hosts -verb runas }
function CustomUpdate { explorer ms-settings:windowsupdate }
function gci_lsd { lsd --group-dirs first $args[0] }
function ToGhqList {
  pushd "$(ghq root)\$(ghq list --vcs=git | fzf)"
}
function q{
  pushd $(ghq list -p | fzf)
}
function GetCurrentPath {
  Convert-Path .
}
function GetCurrentPathAsLinux {

}
function touch($filename) {
  New-Item -type file $filename
}

function ReplaceHomePathNameToChilda {
  $curPath = $ExecutionContext.SessionState.Path.CurrentLocation.Path
  if ($curPath.ToLower().StartsWith($HOME.ToLower())) {
    $curPath = "~" + $curPath.SubString($HOME.Length)
  }
  Write-Host $curPath -ForegroundColor Green

}
function Load10kConfig{
  # Download pwsh10k.omp.json configuration file
  $pwsh10kConfigPath = "$HOME/pwsh10k.omp.json"
  if (-not (Test-Path $pwsh10kConfigPath)) {
    $pwsh10kConfigUrl = "https://raw.githubusercontent.com/Kudostoy0u/pwsh10k/master/pwsh10k.omp.json"
    Invoke-WebRequest -Uri $pwsh10kConfigUrl -OutFile $pwsh10kConfigPath
  }
}


# ----------------------------------------------------------


# Allow all PowerShell scripts to be run (Optional)
Set-ExecutionPolicy -Scope "CurrentUser" -ExecutionPolicy "Unrestricted"

# ------------------ environment variables ------------------
$env:XDG_CONFIG_HOME = "$HOME/.config"
$env:EDITOR='nvim'

AddPathToEnv $env:USERPROFILE\.rye\shims
AddPathToEnv $env:USERPROFILE\go\bin
AddPathToEnv $env:USERPROFILE\.dotnet\tools

. ~/.pwshenv.local.ps1

# Import Modules

Install-PackageIfMissing -PackageName 'JanDeDobbeleer.OhMyPosh'
Install-ModuleIfMissing -ModuleName 'posh-git'
Install-ModuleIfMissing -ModuleName 'PSFzf'
Install-ModuleIfMissing -ModuleName 'PSEverything'
Install-ModuleIfMissing -ModuleName 'ZLocation'

Load10kConfig
oh-my-posh init pwsh --config ~/pwsh10k.omp.json | Invoke-Expression
Enable-PsFzfAliases


Set-PoshPrompt -Theme powerlevel10k_rainbow
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineKeyHandler -Key "Ctrl+n" -Function ForwardWord
# replace 'Ctrl+t' and 'Ctrl+r' with your preferred bindings:
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }


# alias

set-alias v nvim 
set-alias open explorer
set-alias upm openupm
set-alias gf ToGhqList
set-alias -Name cd -Value pushd -Option AllScope
set-alias search Search-Everything

sal vv EditVimRc
sal ll CustomListChildItems
sal sudo CustomSudo
sal hosts CustomHosts
sal update CustomUpdate
sal ls gci_lsd
sal p GetCurrentPath
