" <C-c>で実行を強制終了させる
" quickrunが実行していない場合は<C-c>を呼び出す
nnoremap <expr><silent> <C-c> quickrun#is_running() ? quickrun#sweep_sessions() : "\<C-c>"


" Space qでアクティブウィンドウ以外閉じる
nnoremap <Space>q :only<CR>
