-- https://github.com/sainnhe/gruvbox-material/blob/master/doc/gruvbox-material.txt
--
vim.cmd([[
  let g:gruvbox_material_diagnostic_text_highlight = 1
  let g:gruvbox_material_diagnostic_line_highlight = 0
  let g:gruvbox_material_diagnostic_virtual_text = 'colored'
  let g:gruvbox_material_current_word = 'underline'
  let g:gruvbox_material_statusline_style = 'mix'
  
  augroup vim_entered_cmd
    autocmd!
  augroup END
  
  au vim_entered_cmd VimEnter * nested colorscheme gruvbox-material
]])
