cd E:

# oh-my-posh
Import-Module posh-git
Import-Module oh-my-posh
#Set-Theme Material
Set-PoshPrompt -Theme powerlevel10k_rainbow
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineKeyHandler -Key "Ctrl+n" -Function ForwardWord

# fzf
Import-Module PSFzf
Enable-PsFzfAliases

Import-Module PSEverything

# ZLocation
Import-Module ZLocation
$env:EDITOR='nvim'

# alias
set-alias v nvim 
set-alias open explorer
set-alias upm openupm
set-alias gf ToGhqList
set-alias -Name cd -Value pushd -Option AllScope

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
function CustomChildItemOnlyName { Get-ChildItem -Name }
function GetChildItemLikeLs([int]$columnCount = 6) {
  Get-ChildItem | Format-Wide Name -Column $columnCount
}
sal ls GetChildItemLikeLs

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
