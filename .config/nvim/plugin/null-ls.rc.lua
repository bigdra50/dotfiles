-- mason-null-ls.lua

local mason_null_ls = require("mason-null-ls")
local null_ls = require("null-ls")

-- Mason-null-lsの設定
local function setup_mason_null_ls()
  mason_null_ls.setup({
    ensure_installed = {
      "prettierd",
      "stylua",
    },
    automatic_setup = true,
    automatic_installation = true,
    handlers = {},
  })
end

-- Formatter Sourceの設定（フォーマッター関連をコメントアウト）
local function get_null_ls_sources()
  return {
    null_ls.builtins.completion.spell,
    -- null_ls.builtins.formatting.prettier, -- フォーマッターをコメントアウト
    -- null_ls.builtins.formatting.stylua,   -- フォーマッターをコメントアウト
    --null_ls.builtins.formatting.swiftformat.with({
    --  args = { "--stdinpath", "$FILENAME" },
    --}),
    require("none-ls.diagnostics.eslint"),
  }
end

-- 保存時の自動フォーマット設定をコメントアウト
local function on_attach(client, bufnr)
  -- フォーマット関連の設定をコメントアウト
  -- if not client.supports_method("textDocument/formatting") then
  --   return
  -- end
  -- 
  -- vim.api.nvim_create_autocmd("BufWritePre", {
  --   buffer = bufnr,
  --   callback = function()
  --     vim.lsp.buf.format({
  --       bufnr = bufnr,
  --       filter = function(client)
  --         return client.name == "null-ls"
  --       end,
  --     })
  --   end,
  -- })
end

-- None-lsの設定
local function setup_null_ls()
  null_ls.setup({
    sources = get_null_ls_sources(),
    on_attach = on_attach,
    debug = false,
  })
end

-- フォーマットのキーマップ設定をコメントアウト
local function setup_format_keymap()
  -- vim.keymap.set("n", "<Space>fmt", function()
  --   vim.lsp.buf.format({ async = true })
  -- end)
end

setup_mason_null_ls()
setup_null_ls()
-- setup_format_keymap()