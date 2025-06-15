-- Fern.vim設定
vim.g['fern#renderer'] = "nerdfont"

-- キーマッピング
vim.keymap.set("n", "<Leader>dir", ":Fern . -reveal=% -drawer -toggle -width=30<CR>", { silent = true })

-- glyph-paletteの設定
vim.api.nvim_create_augroup("my-glyph-palette", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = "my-glyph-palette",
  pattern = "fern",
  callback = function()
    vim.cmd("call glyph_palette#apply()")
  end,
})
vim.api.nvim_create_autocmd("FileType", {
  group = "my-glyph-palette", 
  pattern = { "nerdtree", "startify" },
  callback = function()
    vim.cmd("call glyph_palette#apply()")
  end,
})