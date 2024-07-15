-- nvim-treesitterの設定
local status, treesitter = pcall(require, "nvim-treesitter.configs")
if (not status) then return end

treesitter.setup({
  incremental_selection = {
    enable = false,
    keymaps = {
      scope_incremental = "a",
      node_decremental = "z",
    },
  },
  highlight = {
    enable = true,
  },
  indent = { enable = true },
  autotag = { enable = true },
  ensure_installed = {
    "json",
    "yaml",
    "markdown",
    "markdown_inline",
    "lua",
    "gitignore",
    "swift",
  },
  auto_install = true,
})

-- nvim-ts-autotagの設定
local autotag_status, autotag = pcall(require, "nvim-ts-autotag")
if autotag_status then
  autotag.setup()
end

-- TSUpdateコマンドの実行（ビルド相当）
vim.cmd([[TSUpdate]])

-- イベントに基づいてTreesitterを読み込む
vim.api.nvim_create_autocmd({"BufReadPre", "BufNewFile"}, {
  callback = function()
    -- ここに必要な追加の設定やコマンドを記述できます
  end,
})
