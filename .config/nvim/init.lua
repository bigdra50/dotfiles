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
vim.g.python3_host_prog = '~/.venvs/nvim/.venv/bin/python'


if vim.api.nvim_get_option('compatible') then
  vim.api.nvim_set_option('compatible', false)
end

vim.opt.termguicolors = true
vim.api.nvim_set_option('laststatus', 3)

local packer_path = vim.fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'

if vim.fn.empty(vim.fn.glob(packer_path)) > 0 then
  vim.fn.system({
    'git', 'clone', 'https://github.com/wbthomason/packer.nvim', '--depth', '1', packer_path
  })
end

require("base")
-- プラグイン設定の読み込み
require("plugins")