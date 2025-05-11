# PSReadLine.ps1
# PSReadLineの設定とキーバインディング

Write-ProfileLog "PSReadLine設定を読み込みます" "Info"

try {
    # 予測ソースを履歴に設定
    # これにより、過去に入力したコマンドに基づいて補完候補が表示される
    Set-PSReadLineOption -PredictionSource History
    Write-ProfileLog "PSReadLine予測機能を設定しました" "Debug"

    # Ctrl+nでの単語移動
    # カーソルの次の単語へ移動するショートカットを設定
    Set-PSReadLineKeyHandler -Key "Ctrl+n" -Function ForwardWord
    Write-ProfileLog "PSReadLine キーバインド Ctrl+n を設定しました" "Debug"

    # Fuzzy Finder（PSFzf）のキーバインド設定
    # Ctrl+tで履歴検索、Ctrl+rでコマンド実行
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
    Write-ProfileLog "PSFzf キーバインドを設定しました" "Debug"

    # Tabキーにfuzzy補完を割り当て
    # これにより、Tab補完がインテリジェントになる
    Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }
    Write-ProfileLog "PSReadLine Tab補完を設定しました" "Debug"

    Write-ProfileLog "PSReadLine設定が完了しました" "Success"
} catch {
    # エラーが発生した場合はログに記録
    Write-ProfileLog "PSReadLine設定中にエラーが発生しました: $($_.Exception.Message)" "Error"
}
