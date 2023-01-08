let g:airline_theme = 'gruvbox_material'
let g:airline#extensions#tabline#enabled = 1
let g:airline_statusline_ontop = 0
" tabline
let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '|'
let g:airline#extensions#tabline#buffer_idx_mode = 1
" 選択行列の表示をカスタム(デフォルトだと長くて横幅を圧迫するので最小限に)
let g:airline_section_z = airline#section#create(['windowswap', '%3p%% ', 'linenr', ':%3v'])
" vim-virtualenvの拡張(virtualenvを認識しているか確認用に､ 現在activateされているvirtualenvを表示)
let g:airline#extensions#virtualenv#enabled = 1
" gitのHEADからのdiffを非表示
let g:airline#extensions#hunks#enables = 0
" Lintによるエラー､警告を表示
let g:airline#extensions#ale#enabled = 1
let g:airline#extensions#ale#error_symbol = 'E:'
let g:airline#extensions#ale#warning_symbol = 'W:'
