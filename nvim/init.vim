" dein Scripts-----------------------------
 if &compatible
   set nocompatible
 endif
 set runtimepath+=~/.cache/dein/repos/github.com/Shougo/dein.vim
 if dein#load_state('~/.cache/dein')
   call dein#begin('~/.cache/dein')
   call dein#load_toml('~/.config/nvim/dein.toml', {'lazy': 0})
   call dein#load_toml('~/.config/nvim/dein_lazy.toml', {'lazy': 1})
   call dein#end()
   call dein#save_state()
 endif
 filetype plugin indent on
 syntax enable

 if dein#check_install()
   call dein#install()
 endif

" End dein Scripts-------------------------

colorscheme molokai

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
" 数値に対してインクリメント･デクリメント"
nnoremap + <C-a>
nnoremap - <C-x>
