local lspkind = require("lspkind")
local cmp = require("cmp")

cmp.setup({
  snippet = {
    expand = function(args)
      vim.fn["vsnip#anonymous"](args.body)
    end,
  },
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "vsnip" },
    { name = "buffer" },
    { name = "path" },
    { name = "nvim_lsp_signature_help" },
  }),
  mapping = cmp.mapping.preset.insert({
    ['<C-u>'] = cmp.mapping.scroll_docs(-4),
    ['<C-b>'] = cmp.mapping.scroll_docs(4),
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<CR>'] = cmp.mapping.confirm({ select = false, behavior = cmp.ConfirmBehavior.Replace }),
  }),
  experimental = {
    ghost_text = true,
  },
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
  formatting = {
    format = lspkind.cmp_format({
      mode = 'symbol',
      maxwidth = 50,
      ellipsis_char = '...',
    })
  }
})

cmp.setup.cmdline('/', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = 'buffer' }
  }
})

-- コマンドライン補完の設定
local success = pcall(function()
  cmp.setup.cmdline(":", {
    mapping = {
      ['<Tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.confirm({ select = true })
        else
          cmp.complete()
        end
      end, {'c'}),
      ['<C-n>'] = cmp.mapping(cmp.mapping.select_next_item(), {'c'}),
      ['<C-p>'] = cmp.mapping(cmp.mapping.select_prev_item(), {'c'}),
    },
    sources = {
      { name = "cmdline", keyword_length = 1 },
      { name = "path", keyword_length = 1 },
    },
    completion = {
      autocomplete = false,  -- 自動補完を無効化
    },
    preselect = cmp.PreselectMode.Item,  -- 最初の項目を自動選択
  })
  
  -- CmdlineChangedによる自動補完は削除（遅延の原因となるため）
end)

if not success then
  vim.notify("cmp-cmdline setup failed", vim.log.levels.WARN)
end

-- vim-vsnip用
vim.cmd([[
let g:vsnip_filetypes = {}
let g:vsnip_filetypes.javascript = ['javascriptreact']
let g:vsnip_filetypes.typescript = ['typescriptreact']
]])

vim.cmd [[
  set completeopt=menu,menuone,noselect
  highlight! default link CmpItemKind CmpItemMenuDefault
]]