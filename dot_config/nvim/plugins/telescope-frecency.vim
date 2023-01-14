nnoremap <C-j> <cmd>Telescope frecency<cr>
lua << EOF
require"telescope".load_extension("frecency")
EOF
