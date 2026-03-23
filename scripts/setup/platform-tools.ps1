$ErrorActionPreference = "Stop"
. "$PSScriptRoot\lib.ps1"

$ToolsFile = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "tools.toml"

if (-not (Test-Path $ToolsFile)) {
    Write-Err "tools.toml not found at: $ToolsFile"
    exit 1
}

$tomlContent = Get-Content $ToolsFile -Raw

# ---- Scoop tools ----

if (Test-CommandExists "scoop") {
    # Buckets
    if ($tomlContent -match '(?ms)scoop_buckets = \[(.*?)\]') {
        $buckets = $Matches[1] -split ',' | ForEach-Object { $_.Trim(' "') } | Where-Object { $_ }
        $currentBuckets = scoop bucket list
        foreach ($bucket in $buckets) {
            if ($currentBuckets -notcontains $bucket) {
                Write-Info "Adding Scoop bucket: $bucket"
                scoop bucket add $bucket
            } else {
                Write-Success "Bucket already added: $bucket"
            }
        }
    }

    # Tools
    if ($tomlContent -match '(?ms)\[platform\.windows\].*?scoop = \[(.*?)\]') {
        $tools = $Matches[1] -split ',' | ForEach-Object { $_.Trim(' "#').Split('"')[0] } | Where-Object { $_ }
        foreach ($tool in $tools) {
            if (scoop list | Select-String -Pattern "^$tool\s") {
                Write-Success "$tool already installed"
            } else {
                Write-Info "Installing $tool..."
                scoop install $tool
            }
        }
    }
}

# ---- mise ----

if (-not (Test-CommandExists "mise")) {
    Write-Info "Installing mise..."
    if (Test-CommandExists "scoop") {
        scoop install mise
    } else {
        $miseInstaller = "$env:TEMP\mise-installer.ps1"
        Invoke-WebRequest -Uri "https://mise.run/install.ps1" -OutFile $miseInstaller
        & $miseInstaller
    }
    Write-Success "mise installed"
} else {
    Write-Success "mise already installed"
}

# ---- PowerShell modules ----

if ($tomlContent -match '(?ms)powershell_modules = \[(.*?)\]') {
    $modules = $Matches[1] -split ',' | ForEach-Object { $_.Trim(' "') } | Where-Object { $_ }
    foreach ($module in $modules) {
        if (Get-Module -ListAvailable -Name $module) {
            Write-Success "$module already installed"
        } else {
            Write-Info "Installing PowerShell module: $module"
            Install-Module -Name $module -Force -AllowClobber -Scope CurrentUser
        }
    }
}

Write-Success "Platform tools installation completed"
