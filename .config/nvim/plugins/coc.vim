set statusline^=%{coc#status()}
let g:lightline = {
  \'active': {
    \'right': [
      \['coc']
    \]
  \},
  \'component_function': {
    \'coc': 'coc#status'
  \}
\}
highlight CocErrorSign ctermfg=15 ctermbg=196
highlight CocWarnSign ctermfg=0 ctermbg=172

nmap <silent> <space><space> :<C-u>CocList<cr>
nmap <silent> <space>df <Plug>(coc-definition)
nmap <silent> <space>rf <Plug>(coc-references)
nmap <silent> <space>rn <Plug>(coc-rename)
nmap <silent> <space>fmt <Plug>(coc-format)
