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

lspconfig.sourcekit.setup({
  filetypes = { "swift", "objective-c", "objective-cpp", "c", "cpp" },
  on_attach = on_attach,
  -- ref: https://www.swift.org/documentation/articles/zero-to-swift-nvim.html
  capabilities = capabilities,
  --capabilities = {
  --  workspace = {
  --    didChangeWatchedFiles = {
  --      dynamicRegistration = true,
  --    },
  --  },
  --},
  root_dir = lspconfig.util.root_pattern("Package.swift", ".git"),
  -- Use visionOS SDK (UIKit etc.)
  -- ref: https://qiita.com/niusounds/items/5a39b65b54939814a9f9
  -- TODO: Make version dynamic
  --cmd = {
  --  --"/Applications/Xcode-16.0.0.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp",
  --  --"`xcode-select -p`/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp",
  --  "sourcekit-lsp",
  --  "-Xswiftc",
  --  "-sdk",
  --  "-Xswiftc",
  --  -- '`xcrun --sdk iphonesimulator --show-sdk-path`',
  --  --"`xcrun --sdk xrsimulator --show-sdk-path`",
  --  "/Applications/Xcode-16.0.0.app/Contents/Developer/Platforms/XRSimulator.platform/Developer/SDKs/XRSimulator2.0.sdk",
  --  --"/Applications/Xcode-16.0.0.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator17.5.sdk",
  --  "-Xswiftc",
  --  "-target",
  --  "-Xswiftc",
  --  -- 'x86_64-apple-ios`xcrun --sdk iphonesimulator --show-sdk-platform-version`-simulator',
  --  --"arm64-apple-xros`xcrun --sdk xrsimulator --show-sdk-platform-version`-simulator",
  --  --"x86_64-apple-ios18.0-simulator",
  --  "arm64-apple-xros2.0-simulator",
  --},
})

-- nice icons
local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
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