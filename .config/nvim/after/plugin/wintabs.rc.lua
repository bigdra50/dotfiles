-- Wintabs設定
vim.cmd([[
nnoremap <C-e>c <Plug>(wintabs_close)
nnoremap <silent> <C-k> :WintabsNext<CR>
nnoremap <silent> <C-j> :WintabsPrevious<CR>
nnoremap <silent> gt :WintabsNext<CR>
nnoremap <silent> gT :WintabsPrevious<CR>
]])