local plugin = require('utils.plugin')
local keymap = require('utils.keymap')

local telescope = plugin.safe_require('telescope')
if not telescope then return end

telescope.setup({
  defaults = {
    mappings = {
      i = {
        ["<C-u>"] = false,
        ["<C-d>"] = false,
      },
    },
  },
})

-- キーマッピング
local builtin = plugin.safe_require('telescope.builtin')
if builtin then
  keymap.bulk_set({
    { 'n', '<leader>ff', builtin.find_files, { desc = 'Find files' } },
    { 'n', '<leader>fg', builtin.live_grep, { desc = 'Live grep' } },
    { 'n', '<leader>fb', builtin.buffers, { desc = 'Buffers' } },
    { 'n', '<leader>fh', builtin.help_tags, { desc = 'Help tags' } },
  })
end