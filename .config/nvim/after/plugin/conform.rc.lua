local status, conform = pcall(require, "conform")
if not status then
  return
end

local path_utils = require('utils.path')

conform.setup({
  formatters_by_ft = {
    lua = { "stylua" },
    javascript = { "prettier" },
    typescript = { "prettier" },
    javascriptreact = { "prettier" },
    typescriptreact = { "prettier" },
    css = { "prettier" },
    html = { "prettier" },
    json = { "prettier" },
    yaml = { "prettier" },
    markdown = { "prettier" },
    swift = { "swift_format" },
    -- Go formatting handled by go.nvim
    -- 他の言語設定
  },
  formatters = {
    swift_format = {
      command = path_utils.get_tool_path("swift-format"),
      args = { "--mode", "format" },
    },
    -- 他にカスタム設定が必要なフォーマッターがあれば追加
  },
  format_on_save = function(bufnr)
    local ignore_filetypes = { "oil", "go" } -- Go handled by go.nvim
    if vim.tbl_contains(ignore_filetypes, vim.bo[bufnr].filetype) then
      return
    end
    return { timeout_ms = 500, lsp_fallback = true }
  end,
  log_level = vim.log.levels.INFO,
})

-- キーマッピング
vim.keymap.set({ "n", "v" }, "<leader>fmt", function()
  conform.format({
    lsp_fallback = true,
    async = false,
    timeout_ms = 500,
  })
end, { desc = "Format file or range (in visual mode)" })