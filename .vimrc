set encoding=utf-8
set fileencodings=utf=8,cp932,sjis,euc-jp
set nobackup
set modifiable
" 編集中のファイルが変更されたら自動で読み直す
set autoread
" バッファが編集中でもその他のファイルを開けるように
set hidden
" 入力中のコマンドをステータスに表示する
set showcmd
set noswapfile
set title
set matchtime=1
set laststatus=2
set statusline=2

" 長い行でも表示"
set display=lastline
" 補完メニューの高さ"
set pumheight=10
" tabを可視化"
set list listchars=tab:\▶\-
if has('win64')
  set fileformats=dos,unix,mac
else
  set fileformats=unix,dos,mac
endif

" 見た目系
syntax on
" 行番号を表示
set number
" 現在の行を強調表示
set cursorline
" 現在の行を強調表示（縦）
set cursorcolumn
highlight CursorColumn ctermbg=235
" 行末の1文字先までカーソルを移動できるように
set virtualedit=onemore
" インデントはスマートインデント
set smartindent
" ビープ音を可視化
set visualbell
" 括弧入力時の対応する括弧を表示
set showmatch
" ステータスラインを常に表示
set laststatus=2
" コマンドラインの補完
set wildmode=list:longest


" Tab系
" 不可視文字を可視化(タブが「▸-」と表示される)
set list listchars=tab:\▸\-
" Tab文字を半角スペースにする
set expandtab
" 行頭以外のTab文字の表示幅（スペースいくつ分）
set tabstop=2
" 行頭でのTab文字の表示幅
set shiftwidth=2

" 検索系
" 検索文字列が小文字の場合は大文字小文字を区別なく検索する
set ignorecase
" 検索文字列に大文字が含まれている場合は区別して検索する
set smartcase
" 検索文字列入力時に順次対象文字列にヒットさせる
set incsearch
" 検索時に最後まで行ったら最初に戻る
set wrapscan
" 検索語をハイライト表示
set hlsearch
" ESC連打でハイライト解除
nmap <Esc><Esc> :nohlsearch<CR><Esc>
" 移動系
" 折り返し時に表示行単位での移動できるようにする
nnoremap j gj
nnoremap k gk
" カーソル
inoremap <C-e> <Esc>$i
inoremap <C-a> <Esc>^i
noremap <C-e> <Esc>$i
noremap <C-a> <Esc>^i
" Yを行末までのヤンクに"
nnoremap Y y$
inoremap <silent> jj <ESC>
" 数値に対してインクリメント･デクリメント"
nnoremap + <C-a>
nnoremap - <C-x>
" inoremap { {}<LEFT>
" inoremap ( ()<LEFT>
" inoremap < <><LEFT>
" inoremap " ""<LEFT>
" inoremap ' ''<LEFT>
" inoremap [ []<LEFT>

" 補完時
inoremap <expr><CR> pumvisible() ? "<C-y>" : "<CR>"
inoremap <expr><C-n> pumvisible() ? "<Down>" : "<C-n>"
inoremap <expr><C-p> pumvisible() ? "<Up>" : "<C-p>"

nnoremap <silent> <ESC> <C-\><C-n>

nnoremap gr :tabprevious
nnoremap <silent> gT :bprev<CR>
nnoremap <silent> gt :bnext<CR>
