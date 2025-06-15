return {
  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "TSUpdateSync" },
    config = function()
      local configs = require("nvim-treesitter.configs")
      configs.setup({
        ensure_installed = {
          "lua", "vim", "vimdoc", "javascript", "typescript",
          "html", "css", "json", "yaml", "markdown", "swift",
          "python", "go", "rust", "bash", "dockerfile", "gitignore"
        },
        sync_install = false,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  -- ファジーファインダー
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = { "nvim-lua/plenary.nvim" },
  },
  {
    "nvim-telescope/telescope-frecency.nvim",
    dependencies = { 
      "telescope.nvim",
      "kkharji/sqlite.lua",
    },
  },

  -- オートペア、タグ、コメント、サラウンド機能
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
  },
  {
    "windwp/nvim-ts-autotag",
    event = "InsertEnter",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
  },
  {
    "terrortylor/nvim-comment",
    keys = { "gc", "gcc" },
    config = function()
      require("nvim_comment").setup()
    end,
  },
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    config = true,
  },
  {
    "machakann/vim-highlightedyank",
    event = "TextYankPost",
  },

  -- その他のユーティリティ
  {
    "kevinhwang91/nvim-hlslens",
    keys = { "/", "?", "*", "#", "n", "N" },
  },
  {
    "simeji/winresizer",
    cmd = "WinResizerStartResize",
  },
  {
    "rmagatti/auto-session",
    lazy = false,
    config = true,
  },
  {
    "antoinemadec/FixCursorHold.nvim",
    event = "VeryLazy",
  },

  -- デバッグ
  {
    "mfussenegger/nvim-dap",
    keys = { "<F5>", "<F10>", "<F11>", "<F12>" },
  },
  {
    "rcarriga/nvim-dap-ui",
    keys = { "<F5>", "<F10>", "<F11>", "<F12>" },
    dependencies = {
      "nvim-dap",
      "nvim-neotest/nvim-nio",
    },
  },

  -- Git 統合
  {
    "aspeddro/gitui.nvim",
    cmd = "Gitui",
  },
  {
    "tpope/vim-fugitive",
    cmd = { "Git", "Gdiff", "Gstatus", "Gblame" },
  },
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = true,
  },
  {
    "airblade/vim-gitgutter",
    branch = "main",
    event = { "BufReadPre", "BufNewFile" },
  },

  -- ファイルタイプ固有のプラグイン
  {
    "digitaltoad/vim-pug",
    ft = "pug",
  },
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreview", "MarkdownPreviewStop" },
    ft = "markdown",
    build = "cd app && npm install",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
  },

  -- Xcode Build
  {
    "wojciech-kulik/xcodebuild.nvim",
    ft = "swift",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("xcodebuild").setup({})
    end,
  },
}