set fenc=utf-8
set noswapfile
set autoread
set showcmd

set number
set cursorline
set cursorcolumn
set virtualedit=onemore
set smartindent
set showmatch
set statusline=2

set wildmode=list:longest

nnoremap j gj
nnoremap k gk

set list listchars=tab:\▸\-
set expandtab
set tabstop=2
set shiftwidth=2

set ignorecase
set smartcase
set incsearch
set wrapscan
set hlsearch
nmap <Esc><Esc> :nohlsearch<CR><Esc>

" 補完時の挙動 set completeopt=menuone,noinsert
inoremap <expr><CR> pumvisible() ? "<C-y>" : "<CR>"
inoremap <expr><C-n> pumvisible() ? "<Down>" : "<C-n>"
inoremap <expr><C-p> pumvisible() ? "<Up>" : "<C-p>"


if &compatible
  set nocompatible
endif
" Add the dein installation directory into runtimepath
set runtimepath+=~/.cache/dein/repos/github.com/Shougo/dein.vim

if dein#load_state('~/.cache/dein')
  call dein#begin('~/.cache/dein')

  call dein#add('~/.cache/dein/repos/github.com/Shougo/dein.vim')
  call dein#add('Shougo/deoplete.nvim')
  if !has('nvim')
    call dein#add('roxma/nvim-yarp')
    call dein#add('roxma/vim-hug-neovim-rpc')
  endif

  " toml
  call dein#load_toml('~/.config/nvim/dein.toml', {'lazy':0})
  call dein#load_toml('~/.config/nvim/dein_lazy.toml', {'lazy':0})
  " auto install
  if dein#check_install()
    call dein#install()
  endif

  call dein#end()
  call dein#save_state()
endif


" Elm

"if executable('elm-language-server')
"  au User lsp_setup call  lsp#register_server({
"      \ 'name': 'elm-language-server',
"      \ 'cmd': {server_info->[&shell, &shellcmdflag, 'elm-language-server --stdio']},
"      \ 'initialization_options': {
"        \ 'runtime': 'node',
"        \'elmPath': 'elm',
"        \'elmFormatPath': 'elm-format',
"        \'elmTestPath': 'elm-test',
"        \'rootPatterns': 'elm.json'
"        \},
"      \'whitelist': ['elm'],
"      \})
"  autocmd BufWritePre *.elm LspDocumentFormat
"endif
"

"nmap <silent> gd :LspDefinition<CR>
"nmap <silent> <f2> :LspRename<CR>
"nmap <silent> <Leader>d :LspTypeDefinition<CR>
"nmap <silent> <Leader>r :LspReferences<CR>
"nmap <silent> <Leader>i :LspImplementation<CR>
"let g:lsp_diagnostics_enabled = 1
"let g:lsp_diagnostics_echo_cursor = 1
"let g:asyncomplete_popup_delay = 200
"let g:lsp_text_edit_enabled = 0


" カラーテーマ指定してかっこよく
"let g:airline_theme = 'badwolf'
" タブバーをかっこよく
let g:airline#extensions#tabline#enabled = 1
" 選択行列の表示をカスタム(デフォルトだと長くて横幅を圧迫するので最小限に)
let g:airline_section_z = airline#section#create(['windowswap', '%3p%% ', 'linenr', ':%3v'])
"
" virtulenvを認識しているか確認用に、現在activateされているvirtualenvを表示(vim-virtualenvの拡張)
let g:airline#extensions#virtualenv#enabled = 1
" gitのHEADから変更した行の+-を非表示(vim-gitgutterの拡張)
let g:airline#extensions#hunks#enabled = 0
" Lintツールによるエラー、警告を表示(ALEの拡張)
let g:airline#extensions#ale#enabled = 1
let g:airline#extensions#ale#error_symbol = 'E:'
let g:airline#extensions#ale#warning_symbol = 'W:' 
let g:elm_setup_keybindings = 0
filetype plugin indent on
syntax enable 
colorscheme molokai
