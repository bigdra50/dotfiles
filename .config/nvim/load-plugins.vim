" dein Scripts-----------------------------
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

" if has('win32') || has('win64')
"   let g:python3_host_prog = '$PYENV\versions\3.10.5\python.exe'
" endif
