-- Fern の基本設定
vim.g["fern#renderer"] = "nvim-web-devicons"
vim.g["fern#default_hidden"] = 1

-- キーマッピング
local function set_keymap(mode, lhs, rhs, opts)
  vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", { noremap = true }, opts or {}))
end

set_keymap("n", "<C-n>", ":Fern . -reveal=%<CR>", { silent = true })
set_keymap("n", "<Space>dir", ":Fern . -reveal=% -drawer -toggle -width=30<CR>")

-- Fern 固有の設定
local function setup_fern_buffer()
  set_keymap("n", "dd", "<Plug>(fern-action-remove)", { buffer = true, silent = true })
end

-- Fern のバッファ固有の設定を適用
vim.api.nvim_create_autocmd("FileType", {
  pattern = "fern",
  callback = setup_fern_buffer,
})

-- Glyph Palette の設定
local function setup_glyph_palette()
  local group = vim.api.nvim_create_augroup("my-glyph-palette", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = { "fern", "nerdtree", "startify", "dashboard", "alpha", "vista", "vista_kind" },
    callback = function()
      vim.fn["glyph_palette#apply"]()
    end,
  })
end

setup_glyph_palette()
