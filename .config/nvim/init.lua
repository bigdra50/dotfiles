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
-- Use dedicated nvim venv, then uv project, then system python
local function find_python_executable()
  -- First try dedicated nvim venv
  local nvim_venv_python = vim.fn.expand('~/.venvs/nvim/bin/python')
  if vim.fn.filereadable(nvim_venv_python) == 1 then
    return nvim_venv_python
  end
  
  -- Then try uv's project python
  local uv_python = vim.fn.system('uv run --quiet which python 2>/dev/null'):gsub('\n', '')
  if vim.v.shell_error == 0 and vim.fn.filereadable(uv_python) == 1 then
    return uv_python
  end
  
  -- Fallback to system python
  local system_python = vim.fn.exepath('python3') or vim.fn.exepath('python')
  return system_python
end

vim.g.python3_host_prog = find_python_executable()


if vim.api.nvim_get_option('compatible') then
  vim.api.nvim_set_option('compatible', false)
end

vim.opt.termguicolors = true
vim.api.nvim_set_option('laststatus', 3)

require("base")
require("config.lazy")