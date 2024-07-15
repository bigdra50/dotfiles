-- mason-null-ls.lua

-- Mason-null-lsの設定
local function setup_mason_null_ls()
  local status, mason_null_ls = pcall(require, "mason-null-ls")
  if not status then return end

  mason_null_ls.setup({
    ensure_installed = {
      'prettierd',
    },
    automatic_setup = true,
    handlers = {},
  })
end

-- None-lsの設定
local function setup_null_ls()
  local status, null_ls = pcall(require, "none-ls")
  if not status then return end

  local sources = {
    null_ls.builtins.formatting.prettier,
    null_ls.builtins.formatting.stylua,
    null_ls.builtins.completion.spell,
    require('none-ls.diagnostics.eslint')
  }

  null_ls.setup({
    sources = sources,
    debug = false,
  })
end

-- フォーマットのキーマップ設定
local function setup_format_keymap()
  vim.keymap.set('n', '<Space>fmt', function()
    vim.lsp.buf.format { async = true }
  end)
end

-- 設定の実行
setup_mason_null_ls()
setup_null_ls()
setup_format_keymap()
