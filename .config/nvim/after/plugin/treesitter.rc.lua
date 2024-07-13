local status, treesitter = pcall(require, "nvim-treesitter.configs")
if (not status) then return end

require 'nvim-treesitter.install'.compilers = { "/usr/bin/gcc" }
treesitter.setup {
  ensure_installed = {"vim", "dockerfile", "fish", "typescript", "tsx", "javascript", "json", "lua", "gitignore", "bash", "astro", "markdown", "markdown_inline", "css", "scss", "yaml", "toml", "vue", "php", "html"},
  -- ignore_install = { "html" },
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = true, -- catpuucin用
    disable = {"help"},
  },
  indent = {
    enable = true,
  },
}

vim.api.nvim_create_autocmd("FileType", {
  pattern = "help",
  callback = function()
    vim.bo.syntax = "ON"
    vim.bo.filetype = "help"
    -- Tree-sitter を無効にする
    vim.cmd([[TSBufDisable highlight]])
    vim.bo.syntax = "ON"
  end,
})

require('nvim-ts-autotag').setup()
