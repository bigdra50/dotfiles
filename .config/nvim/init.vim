" dein Scripts-----------------------------
 if &compatible
   set nocompatible
 endif
 augroup MyAutoCmd
   autocmd!
 augroup END

 let s:cache_home = empty($XDG_CACHE_HOME) ? expand('~/.cache') : $XDG_CACHE_HOME
 let s:dein_dir = s:cache_home . '/dein'
 let s:dein_repo_dir = s:dein_dir . '/repos/github.com/Shougo/dein.vim'
 if !isdirectory(s:dein_repo_dir)
   call system('git clone https://github.com/Shougo/dein.vim ' . shellescape(s:dein_repo_dir))
 endif
 let &runtimepath = s:dein_repo_dir .",". &runtimepath

 let s:toml_file = fnamemodify(expand('<sfile>'), ':h').'/dein.toml'
 let s:lazy_toml_file = fnamemodify(expand('<sfile>'), ':h').'/dein_lazy.toml'
 if dein#load_state(s:dein_dir)
   call dein#begin(s:dein_dir)
   call dein#load_toml(s:toml_file, {'lazy': 0})
   "call dein#load_toml(s:lazy_toml_file, {'lazy': 1})
   call dein#end()
   call dein#save_state()
 endif

 filetype plugin indent on
 syntax enable

 if has('vim_starting') && dein#check_install()
   call dein#install()
 endif


" End dein Scripts-------------------------

if has('unix')
  let g:python3_host_prog = '$HOME/.config/nvim/nvim-python3/.venv/bin/python3.10'
endif
if has('mac')
endif
if has('win32') || has('win64')
  let g:python3_host_prog = 'C:\Users\ryu19\.pyenv\pyenv-win\shims\python.bat'
endif

set fenc=utf-8
set noswapfile
set autoread
set hidden
set showcmd
set title
set number
set cursorline
set cursorcolumn
set virtualedit=onemore
set visualbell
set smartindent
set showmatch
set matchtime=1
set laststatus=2
set statusline=2
set wildmode=list:longest
set expandtab
set tabstop=2
set shiftwidth=2
set ignorecase
set smartcase
set incsearch
set wrapscan
set hlsearch
" 長い行でも表示"
set display=lastline
" 補完メニューの高さ"
set pumheight=10
" tabを可視化"
set list listchars=tab:\▶\-

" 補完時の挙動
inoremap <expr><CR> pumvisible() ? "<C-y>" : "<CR>"
inoremap <expr><C-n> pumvisible() ? "<Down>" : "<C-n>"
inoremap <expr><C-p> pumvisible() ? "<Up>" : "<C-p>"
" inoremap { {}<LEFT>
" inoremap ( ()<LEFT>
" inoremap < <><LEFT>
" inoremap " ""<LEFT>
" inoremap ' ''<LEFT>
" inoremap [ []<LEFT>

nmap <Esc><Esc> :nohlsearch<CR><Esc>

" Yを行末までのヤンクに"
nnoremap Y y$
nnoremap j gj
nnoremap k gk
inoremap <silent> jj <ESC>
" 数値に対してインクリメント･デクリメント"
nnoremap + <C-a>
nnoremap - <C-x>

" terminal insertモードからESCでterminal normalモードへ戻る
tnoremap <silent> <ESC> <C-\><C-n>
