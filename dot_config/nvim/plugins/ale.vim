" Search for Project root
" Find files using Telescope command-line sugar.
nnoremap <C-p> <cmd>Telescope find_files<cr>
nnoremap <C-g> <cmd>Telescope live_grep<cr>
" プロジェクトルートではなく現在開いているファイルを起点にファイル検索
nnoremap <M-p> <cmd>lua require('telescope.builtin').find_files( { cwd = vim.fn.expand('%:p:h') })<cr>
nnoremap <M-g> <cmd>lua require('telescope.builtin').live_grep( { cwd = vim.fn.expand('%:p:h') })<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>

" Using Lua functions
nnoremap <leader>ff <cmd>lua require('telescope.builtin').find_files()<cr>
nnoremap <leader>fg <cmd>lua require('telescope.builtin').live_grep()<cr>
nnoremap <leader>fb <cmd>lua require('telescope.builtin').buffers()<cr>
nnoremap <leader>fh <cmd>lua require('telescope.builtin').help_tags()<cr>
lua <<EOF
require('telescope').setup{
  defaults = {
    mappings = {
      n = {
        ["<esc>"] = require('telescope.actions').close,
      },
      i = {
        ["<esc>"] = require('telescope.actions').close,
        ["<C-a>"] = require('telescope.actions').send_to_qflist + require('telescope.actions').open_qflist,
        ["<C-q>"] = require('telescope.actions').send_selected_to_qflist + require('telescope.actions').open_qflist
      }
    }
  }
}
EOF
