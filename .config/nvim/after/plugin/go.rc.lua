-- Go specific settings
local opts = { noremap = true, silent = true }

-- Create a dedicated keymap group for Go
vim.api.nvim_create_augroup("GoKeymaps", { clear = true })

-- Autocommands for Go files
vim.api.nvim_create_autocmd("FileType", {
  pattern = "go",
  group = "GoKeymaps",
  callback = function()
    -- Go specific settings
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.expandtab = false
  end,
})