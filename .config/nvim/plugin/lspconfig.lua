local mason = require("mason")
mason.setup()

local lspconfig = require("lspconfig")
local cmp_nvim_lsp = require("cmp_nvim_lsp")
local capabilities = cmp_nvim_lsp.default_capabilities()
local opts = { noremap = true, silent = true }
local on_attach = function(client, bufnr)
  opts.buffer = bufnr

  opts.desc = "Show line diagnostics"
  vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)

  opts.desc = "Show documentation for what is under cursor"
  vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)

  vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
  vim.keymap.set("n", "rn", vim.lsp.buf.rename, opts)
  vim.keymap.set("n", "<leader>i", function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ 0 }), { 0 })
  end, opts)
end

lspconfig["sourcekit"].setup({
  capabilities = capabilities,
  on_attach = on_attach,
  --root_dir = lspconfig.util.root_pattern("Package.swift", ".git"),
})

-- nice icons
local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end

---- 以前の設定から追加: LSP-Diagnostic Settings
--vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
--  vim.lsp.diagnostic.on_publish_diagnostics, {
--    virtual_text = { spacing = 2, prefix = "◆", severity = 'Error' },
--    severity_sort = true,
--    underline = true,
--    update_in_insert = false,
--  }
--)
--
---- 以前の設定から追加: Diagnostic Setting(Global)
--vim.diagnostic.config({
--  virtual_text = { spacing = 2, prefix = "◆", severity = 'Error' },
--  severity_sort = true,
--  underline = true,
--  update_in_insert = false,
--  float = {
--    source = "always",
--  },
--})

-- nvim-lsp-file-operations の設定
local status, lsp_file_operations = pcall(require, "lsp-file-operations")
if status then
  lsp_file_operations.setup()
end
