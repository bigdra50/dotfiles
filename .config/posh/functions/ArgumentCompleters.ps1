# ArgumentCompleters.ps1
# 引数補完関連の機能実装

Write-ProfileLog "引数補完機能を読み込みます" "Info"

# adb コマンド用の引数補完機能を設定
Write-ProfileLog "adbコマンド用の引数補完機能を設定します" "Info"
Register-ArgumentCompleter -CommandName adb -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    
    $commandElements = $commandAst.CommandElements
    
    # "adb shell ls" コマンドの場合のみ処理
    # このパターンに一致する場合のみディレクトリ補完を提供する
    if ($commandElements.Count -ge 3 -and 
        $commandElements[1].Value -eq "shell" -and 
        $commandElements[2].Value -eq "ls") {
        
        Write-ProfileLog "adb shell ls のための補完候補を生成します" "Debug"
        
        # Androidデバイス上のディレクトリを検索し、補完候補として提供
        # 2>/dev/nullでエラー出力を抑制し、アクセス不能なディレクトリを無視
        $directories = adb shell "find / -type d 2>/dev/null" | 
                      Where-Object { $_ -like "$wordToComplete*" } |
                      ForEach-Object {
                          # 補完候補オブジェクトを作成
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

# adbディレクトリブラウジング用のユーザーフレンドリーなインターフェース
Write-ProfileLog "adbls エイリアスを設定します" "Info"
function Get-AdbLsDirectory {
    # Android端末上のディレクトリをグリッドビューで表示して選択できるようにする関数
    # これにより、コマンドラインでパスを入力する手間を省略できる
    $directory = adb shell "find / -type d 2>/dev/null" | Out-GridView -Title "ディレクトリを選択" -OutputMode Single
    if ($directory) {
        # 選択したディレクトリの内容を表示
        adb shell ls $directory
    }
}

# 使いやすいエイリアスを設定
Set-Alias adbls Get-AdbLsDirectory

Write-ProfileLog "引数補完機能の読み込みが完了しました" "Success"
