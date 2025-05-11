# Utility.ps1
# 一般的なユーティリティ関数の実装

Write-ProfileLog "ユーティリティ関数を読み込みます" "Info"

# Unity バージョン情報を取得する関数
function unity-version {
    # ProjectVersion.txtからUnityエディタのバージョンを抽出する
    # このファイルは常にUnityプロジェクトのルートディレクトリに存在する
    (Get-Content .\ProjectSettings\ProjectVersion.txt | 
        Select-String "m_EditorVersion:" | 
        ForEach-Object { $($_-split(" "))[1] })
}

# Unity Android Debug Bridge (ADB) へのショートカット
function uadb {
    # 現在のUnityバージョンに対応するADBを実行する
    # Unity SDKのバージョンを自動的に検出するため、複数のUnityバージョンを
    # 併用する環境でも適切なADBを使用できる
    & "~\opt\unity\$(unity-version)\Editor\Data\PlaybackEngines\AndroidPlayer\SDK\platform-tools\adb.exe" @args
}

# 空のディレクトリを検索する関数
function ls-empty-dirs {
    # プロジェクトのクリーンアップに役立つ、空ディレクトリを検索して表示する
    Get-ChildItem -Directory | 
        Where-Object { -not (Get-ChildItem $_) } | 
        Select-Object -ExpandProperty FullName
}

# ディレクトリ内のファイルを最終更新日時でソートして表示する関数
function CustomListChildItems { 
    # 最新のファイルを上に表示し、同じ日時のファイルは名前順にソートする
    # これにより、最近変更されたファイルを素早く確認できる
    Get-ChildItem $args[0] -force | 
        Sort-Object -Property @{ Expression = 'LastWriteTime'; Descending = $true }, 
                             @{ Expression = 'Name'; Ascending = $true } | 
        Format-Table -AutoSize -Property Mode, Length, LastWriteTime, Name 
}

# Linux風のtouch関数（空ファイルを作成する）
function touch($filename) {
    # Linuxのtouchコマンドと同様の動作をする関数
    # 指定されたファイルが存在しない場合は新規作成する
    New-Item -type file $filename
}

Write-ProfileLog "ユーティリティ関数の読み込みが完了しました" "Success"
