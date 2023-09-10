# ------------------ environment variables ------------------
$env:XDG_CONFIG_HOME = "$HOME/.config"

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

AddPathToEnv $env:USERPROFILE\.rye\shims
AddPathToEnv $env:USERPROFILE\go\bin
AddPathToEnv $env:USERPROFILE\.dotnet\tools

. ~/.pwshenv.local.ps1

# ------------------ environment variables ------------------
# ------------------ package management ------------------
# Install-PackageIfMissing function
function Install-PackageIfMissing {
    param (
        [string]$PackageId
    )
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        if (-not (winget list --id $PackageId -e)) {
            Write-Output "Installing package: $PackageId"
            winget install --id $PackageId
            Write-Output "Package installed: $PackageId"
        }
    } else {
        Write-Output "Winget is not available. Please install winget and try again."
    }
}

# Read packages from the file
# $profileDir = Split-Path -Parent $PROFILE
# $packagesFile = "$profileDir/.packages"
# $packageIds = Get-Content $packagesFile | Where-Object { -not $_.StartsWith("#") }
# 
# # Check and install packages if not installed
# $packageCount = $packageIds.Count
# $currentPackageIndex = 0
# 
# foreach ($packageId in $packageIds){
#     # $currentPackageIndex++
#     # $progress = @{
#     #     Activity = "Checking and installing packages"
#     #     Status = "Processing package $($currentPackageIndex) of $($packageCount): $packageId"
#     #     PercentComplete = ($currentPackageIndex / $packageCount) * 100
#     # }
#     # Write-Progress @progress
#     Install-PackageIfMissing -PackageId $packageId
# }
# ------------------ package management ------------------


function EditVimRc { nvim $UserProfile\.config\nvim\init.vim }
sal vv EditVimRc
function CustomListChildItems { Get-ChildItem $args[0] -force | Sort-Object -Property @{ Expression = 'LastWriteTime'; Descending = $true }, @{ Expression = 'Name'; Ascending = $true } | Format-Table -AutoSize -Property Mode, Length, LastWriteTime, Name }
sal ll CustomListChildItems
function CustomSudo { Start-Process powershell.exe -Verb runas }
sal sudo CustomSudo
function CustomHosts { start notepad C:\Windows\System32\drivers\etc\hosts -verb runas }
sal hosts CustomHosts
function CustomUpdate { explorer ms-settings:windowsupdate }
sal update CustomUpdate
# function CustomChildItemOnlyName { Get-ChildItem -Name }
# function GetChildItemLikeLs([int]$columnCount = 6) {
#   Get-ChildItem | Format-Wide Name -Column $columnCount
# }
function gci_lsd { lsd $args[0] }
sal ls gci_lsd

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
sal p GetCurrentPath
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


# ------------------ posh-git and oh-my-posh setup ------------------
# Allow all PowerShell scripts to be run (Optional)
Set-ExecutionPolicy -Scope "CurrentUser" -ExecutionPolicy "Unrestricted"

# Install posh-git
$poshGitModule = "posh-git"
if (-not (Get-Module -ListAvailable -Name $poshGitModule)) {
    Install-Module -Name $poshGitModule -Scope CurrentUser -Force
}

# Install oh-my-posh
$ohMyPoshPackageId = "JanDeDobbeleer.OhMyPosh"
if (Get-Command winget -ErrorAction SilentlyContinue) {
    if (-not (winget list --id $ohMyPoshPackageId -e)) {
        winget install --id $ohMyPoshPackageId -s winget
    }
} else {
    Write-Host "Winget is not available. Please install winget and try again." -ForegroundColor Red
}

# Download pwsh10k.omp.json configuration file
$pwsh10kConfigPath = "$HOME/pwsh10k.omp.json"
if (-not (Test-Path $pwsh10kConfigPath)) {
  $pwsh10kConfigUrl = "https://raw.githubusercontent.com/Kudostoy0u/pwsh10k/master/pwsh10k.omp.json"
  Invoke-WebRequest -Uri $pwsh10kConfigUrl -OutFile $pwsh10kConfigPath
}

# Import posh-git module
Import-Module $poshGitModule

# Initialize oh-my-posh
oh-my-posh init pwsh --config ~/pwsh10k.omp.json | Invoke-Expression


# ------------------ posh-git and oh-my-posh setup ------------------


#Set-Theme Material
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineKeyHandler -Key "Ctrl+n" -Function ForwardWord
Set-PSReadLineKeyHandler -Key Tab -ScriptBlock {Invoke-FzfTabCompletion}

# fzf
if (-not (Get-Module -Name PSFzf)) {
  Install-Module PSFzf -Scope CurrentUser
}
Import-Module PSFzf
Enable-PsFzfAliases

if (-not (Get-Module -Name PSEverything)) {
  Install-Module PSEverything -Scope CurrentUser
}
Import-Module PSEverything

# ZLocation
if (-not (Get-Module -Name ZLocation)) {
  Install-Module ZLocation -Scope CurrentUser
}
Import-Module ZLocation

$env:EDITOR='nvim'

# alias
set-alias v nvim 
set-alias open explorer
set-alias upm openupm
set-alias gf ToGhqList
set-alias -Name cd -Value pushd -Option AllScope


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
