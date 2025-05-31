vim.cmd [[source ~/.vimrc]]
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
