-- Load .vimrc but skip termencoding which is not supported in Neovim
local vimrc_path = vim.fn.expand("~/.vimrc")
if vim.fn.filereadable(vimrc_path) == 1 then
  local vimrc_content = vim.fn.readfile(vimrc_path)
  for _, line in ipairs(vimrc_content) do
    if not line:match("^%s*set%s+termencoding") then
      pcall(vim.cmd, line)
    end
  end
end
--vim.opt.runtimepath:append("~/.config/nvim")
-- Use path utility for Python executable detection
local path_utils = require('utils.path')
vim.g.python3_host_prog = path_utils.find_python_venv()


if vim.api.nvim_get_option('compatible') then
  vim.api.nvim_set_option('compatible', false)
end

vim.opt.termguicolors = true
vim.api.nvim_set_option('laststatus', 3)

require("base")
require("config.lazy")