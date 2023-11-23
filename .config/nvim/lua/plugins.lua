local status, packer = pcall(require, "packer")
if (not status) then
  print("Packer is not installed")
  return
end

vim.cmd [[packadd packer.nvim]]

packer.startup(function(use)
  -- Packer 自体の管理
  use 'wbthomason/packer.nvim'

  -- 共通依存ライブラリ
  use 'nvim-lua/plenary.nvim' -- Common utilities

  -- カラースキーム
  use 'sainnhe/gruvbox-material'
  use 'rose-pine/neovim'
  use 'sainnhe/everforest'
  use 'folke/lsp-colors.nvim'

  -- インデントとブランクライン表示
  use 'lukas-reineke/indent-blankline.nvim'

  -- カーソルホールドの修正
  use 'antoinemadec/FixCursorHold.nvim'

  -- ステータスラインとタブ管理
  use 'nvim-lualine/lualine.nvim' -- Statusline
  use 'zefei/vim-wintabs'
  use 'zefei/vim-wintabs-powerline'

  -- ファイルエクスプローラーとアイコン
  use 'lambdalisue/fern.vim'
  use 'lambdalisue/nerdfont.vim'
  use 'lambdalisue/fern-renderer-nerdfont.vim'
  use 'kyazdani42/nvim-web-devicons'
  use 'lambdalisue/glyph-palette.vim'

  -- LSPと補完
  use {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "neovim/nvim-lspconfig",
  }
  use 'hrsh7th/nvim-cmp'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-vsnip'
  use 'hrsh7th/cmp-buffer'
  use 'hrsh7th/cmp-path'
  use 'hrsh7th/cmp-cmdline'
  use 'hrsh7th/cmp-nvim-lsp-signature-help'
  use 'hrsh7th/vim-vsnip'
  use 'onsails/lspkind.nvim'
  use 'glepnir/lspsaga.nvim'
  use 'j-hui/fidget.nvim'

  -- Treesitter
  use {
    'nvim-treesitter/nvim-treesitter',
    run = function() require('nvim-treesitter.install').update({ with_sync = true }) end,
  }

  -- ファイルタイプ固有のプラグイン
  use 'digitaltoad/vim-pug'
  use({
    "iamcco/markdown-preview.nvim",
    run = "cd app && npm install",
    setup = function() vim.g.mkdp_filetypes = { "markdown" } end,
    ft = { "markdown" },
  })

  -- Linterとフォーマッター
  use({
    "jose-elias-alvarez/null-ls.nvim",
    requires = { "nvim-lua/plenary.nvim" },
  })
  use({
    "jay-babu/mason-null-ls.nvim",
    requires = { "jose-elias-alvarez/null-ls.nvim" },
  })

  -- ファジーファインダーと拡張機能
  use 'nvim-telescope/telescope.nvim'
  use {
    "nvim-telescope/telescope-frecency.nvim",
    requires = { "kkharji/sqlite.lua" }
  }

  -- オートペア、タグ、コメント、サラウンド機能
  use 'windwp/nvim-autopairs'
  use 'windwp/nvim-ts-autotag'
  use "terrortylor/nvim-comment"
  use "kylechui/nvim-surround"
  use 'machakann/vim-highlightedyank'

  -- その他のユーティリティ
  use 'kevinhwang91/nvim-hlslens'
  use 'norcalli/nvim-colorizer.lua'
  use 'simeji/winresizer'

  -- Git 統合
  use 'kdheepak/lazygit.nvim'
  use 'tpope/vim-fugitive'
  use 'lewis6991/gitsigns.nvim'
  use { 'airblade/vim-gitgutter', branch = 'main' }

  -- その他のプラグイン
  use 'github/copilot.vim'

  -- ChatGPTの統合
  use({
    "jackMort/ChatGPT.nvim",
    config = function()
      require("chatgpt").setup({
        -- optional configuration
      })
    end,
    requires = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim"
    }
  })
end)
