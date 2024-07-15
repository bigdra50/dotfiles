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
  use {
    'folke/trouble.nvim',
    requires = {
      'nvim-tree/nvim-web-devicons'
    },
    event = { 'BufReadPre', 'BufNewFile' }
  }

  use 'mfussenegger/nvim-dap'
  use {
    'rcarriga/nvim-dap-ui',
    requires = {
      'mfussenegger/nvim-dap',
      'nvim-neotest/nvim-nio'
    }
  }

  use {
    'wojciech-kulik/xcodebuild.nvim',
    requires = {
      'nvim-telescope/telescope.nvim',
      'MunifTanjim/nui.nvim',
      'nvim-tree/nvim-tree.lua',       -- (オプション) プロジェクトファイルの管理用
      'stevearc/oil.nvim',             -- (オプション) プロジェクトファイルの管理用
      'nvim-treesitter/nvim-treesitter', -- (オプション) クイックテストサポート用（Swiftパーサーが必要）
    },
    config = function()
      require("xcodebuild").setup({
        -- ここにオプションを追加するか、デフォルト設定を使用する場合は空のままにします
      })
    end
  }


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

  use({
    'MeanderingProgrammer/markdown.nvim',
    as = 'render-markdown',                             -- Only needed if you have another plugin named markdown.nvim
    after = { 'nvim-treesitter' },
    requires = { 'echasnovski/mini.nvim', opt = true }, -- if you use the mini.nvim suite
    -- requires = { 'echasnovski/mini.icons', opt = true }, -- if you use standalone mini plugins
    -- requires = { 'nvim-tree/nvim-web-devicons', opt = true }, -- if you prefer nvim-web-devicons
    config = function()
      require('render-markdown').setup({})
    end,
  })

  -- Linterとフォーマッター
  use({
    'nvimtools/none-ls.nvim',
    requires = { 'nvim-lua/plenary.nvim' }
  })

  use {
    'jay-babu/mason-null-ls.nvim',
    requires = {
      'williamboman/mason.nvim',
      'nvimtools/none-ls.nvim',
    },
    event = { 'BufReadPre', 'BufNewFile' }
  }

  use "j-hui/fidget.nvim"

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
end)
