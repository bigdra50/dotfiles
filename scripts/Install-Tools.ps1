# ============================================================================
# PowerShell Tool Installation Script
# Reads tools.toml and installs tools for Windows/PowerShell environment
# ============================================================================

param(
    [string]$ToolsFile = "$PSScriptRoot\..\tools.toml",
    [switch]$NoScoop,
    [switch]$NoCargo,
    [switch]$NoModules
)

# Colors for output
$script:Colors = @{
    Info = "Cyan"
    Success = "Green"
    Warning = "Yellow"
    Error = "Red"
}

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Type = "Info"
    )
    Write-Host $Message -ForegroundColor $script:Colors[$Type]
}

function Test-CommandExists {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

function Install-Scoop {
    if (-not (Test-CommandExists "scoop")) {
        Write-ColorOutput "Installing Scoop..." "Info"
        try {
            Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
            Write-ColorOutput "Scoop installed successfully!" "Success"
        }
        catch {
            Write-ColorOutput "Failed to install Scoop: $_" "Error"
            return $false
        }
    }
    else {
        Write-ColorOutput "Scoop already installed" "Success"
    }
    return $true
}

function Install-ScoopBuckets {
    param([string[]]$Buckets)
    
    $currentBuckets = scoop bucket list
    foreach ($bucket in $Buckets) {
        if ($currentBuckets -notcontains $bucket) {
            Write-ColorOutput "Adding Scoop bucket: $bucket" "Info"
            scoop bucket add $bucket
        }
        else {
            Write-ColorOutput "Bucket already added: $bucket" "Success"
        }
    }
}

function Install-ScoopTools {
    param([string[]]$Tools)
    
    foreach ($tool in $Tools) {
        if (scoop list | Select-String -Pattern "^$tool\s") {
            Write-ColorOutput "$tool already installed" "Success"
        }
        else {
            Write-ColorOutput "Installing $tool..." "Info"
            scoop install $tool
        }
    }
}

function Install-CargoTools {
    if (-not (Test-CommandExists "cargo")) {
        Write-ColorOutput "Cargo not found. Please install Rust first." "Warning"
        Write-ColorOutput "Visit: https://rustup.rs/" "Info"
        return
    }
    
    # Parse tools.toml for cargo tools
    $tomlContent = Get-Content $ToolsFile -Raw
    
    # Simple regex to extract tool names from cargo section
    $cargoSection = $tomlContent -match '(?ms)\[cargo\].*?(?=\[|$)'
    if ($Matches) {
        $toolMatches = [regex]::Matches($Matches[0], 'name = "([^"]+)"')
        
        foreach ($match in $toolMatches) {
            $toolName = $match.Groups[1].Value
            
            if (Test-CommandExists $toolName) {
                Write-ColorOutput "$toolName already installed" "Success"
            }
            else {
                Write-ColorOutput "Installing $toolName via cargo..." "Info"
                cargo install $toolName
            }
        }
    }
    
    # Install Windows-specific cargo tools
    $windowsCargoSection = $tomlContent -match '(?ms)cargo_windows.*?(?=\[|$)'
    if ($Matches) {
        $toolMatches = [regex]::Matches($Matches[0], 'name = "([^"]+)"')
        
        foreach ($match in $toolMatches) {
            $toolName = $match.Groups[1].Value
            
            if (Test-CommandExists $toolName) {
                Write-ColorOutput "$toolName already installed" "Success"
            }
            else {
                Write-ColorOutput "Installing $toolName via cargo..." "Info"
                cargo install $toolName
            }
        }
    }
}

function Install-PowerShellModules {
    param([string[]]$Modules)
    
    # Ensure PowerShellGet is up to date
    if (-not (Get-Module -ListAvailable -Name PowerShellGet | Where-Object {$_.Version -ge "2.0.0"})) {
        Write-ColorOutput "Updating PowerShellGet..." "Info"
        Install-Module PowerShellGet -Force -AllowClobber
    }
    
    foreach ($module in $Modules) {
        if (Get-Module -ListAvailable -Name $module) {
            Write-ColorOutput "$module already installed" "Success"
        }
        else {
            Write-ColorOutput "Installing PowerShell module: $module" "Info"
            Install-Module -Name $module -Force -AllowClobber -Scope CurrentUser
        }
    }
}

function Install-Mise {
    if (-not (Test-CommandExists "mise")) {
        Write-ColorOutput "Installing mise..." "Info"
        
        # Download and run mise installer
        $miseInstaller = "$env:TEMP\mise-installer.ps1"
        Invoke-WebRequest -Uri "https://mise.run/install.ps1" -OutFile $miseInstaller
        & $miseInstaller
        
        # Add to PATH
        $misePath = "$env:LOCALAPPDATA\mise\bin"
        if ($env:Path -notlike "*$misePath*") {
            [Environment]::SetEnvironmentVariable("Path", "$env:Path;$misePath", [EnvironmentVariableTarget]::User)
            $env:Path += ";$misePath"
        }
        
        Write-ColorOutput "mise installed successfully!" "Success"
    }
    else {
        Write-ColorOutput "mise already installed" "Success"
    }
}

# Main execution
function Main {
    Write-Host "`n🚀 PowerShell Tool Installation" -ForegroundColor Magenta
    Write-Host "================================`n" -ForegroundColor Magenta
    
    # Check if tools.toml exists
    if (-not (Test-Path $ToolsFile)) {
        Write-ColorOutput "tools.toml not found at: $ToolsFile" "Error"
        exit 1
    }
    
    # Read tools.toml
    $tomlContent = Get-Content $ToolsFile -Raw
    
    # Install Scoop and tools
    if (-not $NoScoop) {
        if (Install-Scoop) {
            # Parse and install buckets
            if ($tomlContent -match '(?ms)scoop_buckets = \[(.*?)\]') {
                $buckets = $Matches[1] -split ',' | ForEach-Object { $_.Trim(' "') }
                Install-ScoopBuckets $buckets
            }
            
            # Parse and install tools
            if ($tomlContent -match '(?ms)\[platform\.windows\].*?scoop = \[(.*?)\]') {
                $tools = $Matches[1] -split ',' | ForEach-Object { $_.Trim(' "#').Split('"')[0] } | Where-Object { $_ }
                Install-ScoopTools $tools
            }
        }
    }
    
    # Install mise
    Install-Mise
    
    # Install cargo tools
    if (-not $NoCargo) {
        Install-CargoTools
    }
    
    # Install PowerShell modules
    if (-not $NoModules) {
        if ($tomlContent -match '(?ms)powershell_modules = \[(.*?)\]') {
            $modules = $Matches[1] -split ',' | ForEach-Object { $_.Trim(' "') }
            Install-PowerShellModules $modules
        }
    }
    
    Write-Host "`n✅ Tool installation completed!" -ForegroundColor Green
    Write-Host "`n💡 Restart PowerShell to ensure all tools are in PATH" -ForegroundColor Yellow
}

# Run main
Main