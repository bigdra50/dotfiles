$HOMEDRIVE = "D:\"
$HOMEPATH = "Dev\"
# タイトルを変更
$a = (Get-Host).UI.RawUI
$a.WindowTitle = "三( `・ω・)＼＼|| Powershell//／／(・ω・´ )三"

# 開始ディレクトリの指定
Set-Location "$HOMEDRIVE$HOMEPATH"
Remove-Variable -Force HOME
Set-Variable HOME "$HOMEDRIVE$HOMEPATH" -Force
(get-psprovider 'FileSystem').Home = $HOMEDRIVE + $HOMEPATH

# oh-my-posh
Import-Module posh-git
Import-Module oh-my-posh
Set-Theme Material

# alias
set-alias vim 'C:\Program Files\Vim\vim82\vim.exe' 
#set-alias v 'C:\Program Files\Vim\vim82\vim.exe' 
set-alias v nvim 
function ToCDriveHome {cd C:\Users\ryudai\}
sal c ToCDriveHome

function EditPoshRc {nvim $profile}
sal vp EditPoshRc
function EditVimRc {nvim C:\Users\ryudai\.config\nvim\init.vim}
sal vv EditVimRc
function CustomListChildItems { Get-ChildItem $args[0] -force | Sort-Object -Property @{ Expression = 'LastWriteTime'; Descending = $true }, @{ Expression = 'Name'; Ascending = $true } | Format-Table -AutoSize -Property Mode, Length, LastWriteTime, Name }
sal ll CustomListChildItems
function CustomListChildItems { Get-ChildItem $args[0] -force | Sort-Object -Property @{ Expression = 'LastWriteTime'; Descending = $true }, @{ Expression = 'Name'; Ascending = $true } | Format-Table -AutoSize -Property Mode, Length, LastWriteTime, Name }
sal ll CustomListChildItems
function CustomSudo {Start-Process powershell.exe -Verb runas}
sal sudo CustomSudo
function CustomHosts {start notepad C:\Windows\System32\drivers\etc\hosts -verb runas}
sal hosts CustomHosts
function CustomUpdate {explorer ms-settings:windowsupdate}
sal update CustomUpdate
function CustomChildItemOnlyName {Get-ChildItem -Name}
sal ls CustomChildItemOnlyName
