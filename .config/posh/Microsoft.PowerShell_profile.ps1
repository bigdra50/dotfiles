# Global variables
$script:IsDebug = $env:PWSH_DEBUG -eq "true"
$script:LogFile = "$HOME/.pwsh-profile.log"
$ompCheckFlag = "$HOME/.omp_installed"

# Log function for consistent logging and conditional display
function Write-ProfileLog {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,
        
        [Parameter(Position = 1)]
        [ValidateSet("Info", "Warning", "Error", "Debug", "Success")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Always record to log file
    Add-Content -Path $script:LogFile -Value $logMessage -Encoding UTF8
    
    # Set color for console output
    $foregroundColor = switch ($Level) {
        "Info"    { "Cyan" }
        "Warning" { "Yellow" }
        "Error"   { "Red" }
        "Debug"   { "Magenta" }
        "Success" { "Green" }
        default   { "White" }
    }
    
    # Show messages based on level and debug mode
    $shouldDisplay = switch ($Level) {
        "Warning" { $true }  # Always show warnings
        "Error"   { $true }  # Always show errors
        default   { $script:IsDebug }  # Show others only in debug mode
    }
    
    if ($shouldDisplay) {
        Write-Host $logMessage -ForegroundColor $foregroundColor
    }
}

# Start profile logging
Write-ProfileLog "Starting profile initialization" "Info"
if ($script:IsDebug) {
    Write-ProfileLog "Debug mode enabled" "Debug"
}

# ------------------- utility functions ---------------------
Write-ProfileLog "Loading utility functions" "Info"

function unity-version {
    (Get-Content .\ProjectSettings\ProjectVersion.txt | Select-String "m_EditorVersion:" | %{$($_-split(" "))[1]})
}

function uadb {
    & "~\opt\unity\$(unity-version)\Editor\Data\PlaybackEngines\AndroidPlayer\SDK\platform-tools\adb.exe" @args
}

function ls-empty-dirs{
    Get-ChildItem -Directory | Where-Object { -not (Get-ChildItem $_) } | Select-Object -ExpandProperty FullName
}
Write-ProfileLog "Utility functions loaded" "Success"

# ------------------ package management ------------------
Write-ProfileLog "Loading package management functions" "Info"

function Install-PackageIfMissing {
    param (
        [string]$PackageName
    )
    Write-ProfileLog "Checking package $PackageName" "Debug"
    $installed = winget list --id $PackageName -e | Out-String
    if (-not $installed.Contains($PackageName)) {
        Write-ProfileLog "Installing package $PackageName" "Warning"
        winget install --id $PackageName -e --source winget
    } else {
        Write-ProfileLog "Package $PackageName is already installed" "Debug"
    }
}

function Install-ModuleIfMissing {
    param (
        [string]$ModuleName
    )
    Write-ProfileLog "Checking module $ModuleName" "Debug"
    if (-not (Get-Module -ListAvailable -Name $ModuleName)) {
        Write-ProfileLog "Installing module $ModuleName" "Warning"
        Install-Module -Name $ModuleName -Scope CurrentUser -Force
    } else {
        Write-ProfileLog "Module $ModuleName is already installed" "Debug"
    }
}
Write-ProfileLog "Package management functions loaded" "Success"

# ------------------ helper functions ------------------
Write-ProfileLog "Loading helper functions" "Info"

function EditVimRc { nvim $UserProfile\.config\nvim\init.vim }
function AddPathToEnv {
    param (
        [string]$Path
    )
    Write-ProfileLog "Adding $Path to PATH" "Debug"
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
Write-ProfileLog "Helper functions loaded" "Success"

# Set up argument completer for adb
Write-ProfileLog "Setting up argument completer" "Info"
Register-ArgumentCompleter -CommandName adb -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    
    $commandElements = $commandAst.CommandElements
    
    # Process only for "adb shell ls" commands
    if ($commandElements.Count -ge 3 -and 
        $commandElements[1].Value -eq "shell" -and 
        $commandElements[2].Value -eq "ls") {
        
        Write-ProfileLog "Generating completion candidates for adb shell ls" "Debug"
        $directories = adb shell "find / -type d 2>/dev/null" | 
                      Where-Object { $_ -like "$wordToComplete*" } |
                      ForEach-Object {
                          [System.Management.Automation.CompletionResult]::new(
                              $_, 
                              $_, 
                              'ParameterValue', 
                              $_
                          )
                      }
        
        return $directories
    }
}
Write-ProfileLog "Argument completer set up" "Success"

# User-friendly alias for adb directory browsing
Write-ProfileLog "Setting up adbls alias" "Info"
function Get-AdbLsDirectory {
    $directory = adb shell "find / -type d 2>/dev/null" | Out-GridView -Title "Select Directory" -OutputMode Single
    if ($directory) {
        adb shell ls $directory
    }
}
Set-Alias adbls Get-AdbLsDirectory
Write-ProfileLog "adbls alias set up" "Success"

# Set execution policy
Write-ProfileLog "Setting execution policy" "Info"
Set-ExecutionPolicy -Scope "CurrentUser" -ExecutionPolicy "Unrestricted"
Write-ProfileLog "Execution policy set" "Success"

# Environment variables
Write-ProfileLog "Setting environment variables" "Info"
$env:XDG_CONFIG_HOME = "$HOME/.config"
$env:EDITOR='nvim'

AddPathToEnv $env:USERPROFILE\.rye\shims
AddPathToEnv $env:USERPROFILE\go\bin
AddPathToEnv $env:USERPROFILE\.dotnet\tools
Write-ProfileLog "Environment variables set" "Success"

# Load local environment
Write-ProfileLog "Loading local environment" "Info"
try {
    if (Test-Path ~/.pwshenv.local.ps1) {
        . ~/.pwshenv.local.ps1
        Write-ProfileLog "Local environment loaded" "Success"
    } else {
        Write-ProfileLog "~/.pwshenv.local.ps1 not found, skipping" "Warning"
    }
} catch {
    Write-ProfileLog "Error loading local environment: $($_.Exception.Message)" "Error"
}

# Only check for installation on first run to optimize startup time
$startTime = Get-Date
if (-not (Test-Path $ompCheckFlag)) {
    Write-ProfileLog "First-time setup: Checking required packages" "Warning"
    
    # Check for Oh My Posh
    try {
        Install-PackageIfMissing -PackageName 'JanDeDobbeleer.OhMyPosh'
        Write-ProfileLog "Oh My Posh package checked" "Success"
    } catch {
        Write-ProfileLog "Error installing Oh My Posh: $($_.Exception.Message)" "Error"
    }
    
    # Check for modules
    $modules = @('posh-git', 'PSFzf', 'PSEverything', 'ZLocation')
    foreach ($moduleName in $modules) {
        try {
            Install-ModuleIfMissing -ModuleName $moduleName
            Write-ProfileLog "$moduleName module checked" "Success"
        } catch {
            Write-ProfileLog "Error installing $moduleName`: $($_.Exception.Message)" "Error"
        }
    }
    
    # Create flag to avoid checks on subsequent runs
    "Oh My Posh installation check completed on $(Get-Date)" | Out-File -FilePath $ompCheckFlag
    Write-ProfileLog "Setup complete. This check won't run on subsequent startups" "Success"
} else {
    Write-ProfileLog "Skipping package installation check (already completed)" "Info"
}
$installCheckTime = (Get-Date) - $startTime

# Import modules
Write-ProfileLog "Importing modules" "Info"

try {
    Write-ProfileLog "Enabling PSFzf aliases" "Info"
    Enable-PsFzfAliases
    Write-ProfileLog "PSFzf aliases enabled" "Success"
} catch {
    Write-ProfileLog "Error enabling PSFzf aliases: $($_.Exception.Message)" "Error"
}

# Load Oh My Posh on every run (optimized section)
$startTime = Get-Date
Write-ProfileLog "Loading Oh My Posh config" "Info"
try {
    oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\easy-term.omp.json" | Invoke-Expression
    Write-ProfileLog "Oh My Posh loaded successfully" "Success"
} catch {
    Write-ProfileLog "Error loading Oh My Posh config: $($_.Exception.Message)" "Error"
}
$ompLoadTime = (Get-Date) - $startTime

# Set up PSReadLine options
Write-ProfileLog "Setting up PSReadLine options" "Info"
try {
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineKeyHandler -Key "Ctrl+n" -Function ForwardWord
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
    Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }
    Write-ProfileLog "PSReadLine options set" "Success"
} catch {
    Write-ProfileLog "Error setting up PSReadLine options: $($_.Exception.Message)" "Error"
}

# Set up aliases
Write-ProfileLog "Setting up aliases" "Info"
try {
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
    Write-ProfileLog "Aliases set up" "Success"
} catch {
    Write-ProfileLog "Error setting up aliases: $($_.Exception.Message)" "Error"
}

# Function to manually check for dependencies updates
function Update-OhMyPoshDependencies {
    # Remove the check flag to force reinstallation check
    if (Test-Path $ompCheckFlag) {
        Remove-Item $ompCheckFlag -Force
    }
    
    Write-Host "Running Oh My Posh installation check..." -ForegroundColor Cyan
    Write-ProfileLog "Manually running Oh My Posh installation check" "Warning"
    
    # Check for Oh My Posh
    try {
        Install-PackageIfMissing -PackageName 'JanDeDobbeleer.OhMyPosh'
        Write-Host "Oh My Posh package checked" -ForegroundColor Green
    } catch {
        Write-Host "Error installing Oh My Posh: $($_.Exception.Message)" -ForegroundColor Red
        Write-ProfileLog "Error installing Oh My Posh: $($_.Exception.Message)" "Error"
    }
    
    # Check for modules
    $modules = @('posh-git', 'PSFzf', 'PSEverything', 'ZLocation')
    foreach ($moduleName in $modules) {
        try {
            Install-ModuleIfMissing -ModuleName $moduleName
            Write-Host "$moduleName module checked" -ForegroundColor Green
        } catch {
            Write-Host "Error installing $moduleName`: $($_.Exception.Message)" -ForegroundColor Red
            Write-ProfileLog "Error installing $moduleName`: $($_.Exception.Message)" "Error"
        }
    }
    
    # Recreate flag
    "Oh My Posh installation check completed on $(Get-Date)" | Out-File -FilePath $ompCheckFlag
    Write-Host "Dependencies update complete" -ForegroundColor Green
    Write-ProfileLog "Dependencies update complete" "Success"
}

# Log utility functions
function Show-ProfileLog {
    param (
        [int]$Last = 50,
        [switch]$All
    )
    
    if (Test-Path $script:LogFile) {
        if ($All) {
            Get-Content $script:LogFile | Out-Host
        } else {
            Get-Content $script:LogFile -Tail $Last | Out-Host
        }
    } else {
        Write-Host "Log file not found: $script:LogFile" -ForegroundColor Red
    }
}

function Clear-ProfileLog {
    if (Test-Path $script:LogFile) {
        Remove-Item $script:LogFile -Force
        New-Item $script:LogFile -ItemType File | Out-Null
        Write-Host "Profile log cleared" -ForegroundColor Green
    } else {
        Write-Host "Log file not found: $script:LogFile" -ForegroundColor Yellow
    }
}

# Profile complete
Write-ProfileLog "Profile initialization complete" "Success"
Write-ProfileLog "Oh My Posh load time: $($ompLoadTime.TotalMilliseconds) ms" "Info"

# Display installation check time stats
if (Test-Path $ompCheckFlag) {
    Write-ProfileLog "Installation check skipped (saved ~2800ms)" "Info"
} else {
    Write-ProfileLog "Installation check time: $($installCheckTime.TotalMilliseconds) ms" "Info"
}

# Always display basic information (only in debug mode)
if ($script:IsDebug) {
    Write-Host "Profile loaded" -ForegroundColor Green
    Write-Host "Oh My Posh load time: $($ompLoadTime.TotalMilliseconds) ms" -ForegroundColor Cyan
    Write-Host "Log file: $script:LogFile" -ForegroundColor Cyan
    Write-Host "Available commands: Update-OhMyPoshDependencies, Show-ProfileLog, Clear-ProfileLog" -ForegroundColor Yellow
}
