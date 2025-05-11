# Aliases.ps1
# エイリアス設定の実装

Write-ProfileLog "エイリアス設定を読み込みます" "Info"

try {
    # 基本エイリアス - 短いコマンド名で長いコマンドを実行するためのもの
    # 頻繁に使用するコマンドの入力を簡略化するために設定
    
    # nvimをvで呼び出せるように設定
    # エディタへの素早いアクセスを提供
    Set-Alias v nvim
    
    # Windowsのexplorerをopenコマンドで呼び出せるように設定
    # Unix/Linuxとの互換性のため
    Set-Alias open explorer
    
    # openUPMパッケージマネージャーへのショートカット
    Set-Alias upm openupm
    
    # ghqリストへのショートカット
    Set-Alias gf ToGhqList
    
    # cdコマンドをpushdにリダイレクト
    # これにより、ディレクトリ移動履歴が維持される
    Set-Alias -Name cd -Value pushd -Option AllScope
    
    # Search-Everythingコマンドへのショートカット
    Set-Alias search Search-Everything

    # より複雑なエイリアス - Set-Alias（sal）を使用して設定
    
    # Vimrc編集用エイリアス
    Set-Alias -Name vv -Value EditVimRc
    
    # カスタムのls表示用エイリアス
    Set-Alias -Name ll -Value CustomListChildItems
    
    # 管理者権限実行用エイリアス
    Set-Alias -Name sudo -Value CustomSudo
    
    # hostsファイル編集用エイリアス
    Set-Alias -Name hosts -Value CustomHosts
    
    # Windows Update設定用エイリアス
    Set-Alias -Name update -Value CustomUpdate
    
    # lsdコマンドを使用したディレクトリリスト表示
    Set-Alias -Name ls -Value gci_lsd
    
    # 現在のパス取得用エイリアス
    Set-Alias -Name p -Value GetCurrentPath
    
    Write-ProfileLog "エイリアスの設定が完了しました" "Success"
} catch {
    # エラー発生時のログ記録
    Write-ProfileLog "エイリアス設定中にエラーが発生しました: $($_.Exception.Message)" "Error"
}
