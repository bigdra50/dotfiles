return {
  -- カラースキーム
  {
    "sainnhe/gruvbox-material",
    priority = 1000,
    config = function()
      -- gruvbox設定は after/plugin/gruvbox.rc.lua で管理
    end,
  },
  {
    "sainnhe/everforest",
    priority = 1000,
  },
  {
    "folke/lsp-colors.nvim",
    event = "BufRead",
  },

  -- ステータスラインとタブ管理
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
  },
  {
    "zefei/vim-wintabs",
    event = "VeryLazy",
  },
  {
    "zefei/vim-wintabs-powerline",
    event = "VeryLazy",
    dependencies = { "zefei/vim-wintabs" },
  },

  -- ファイルエクスプローラーとアイコン
  {
    "lambdalisue/fern.vim",
    cmd = "Fern",
    dependencies = {
      "lambdalisue/nerdfont.vim",
      "lambdalisue/fern-renderer-nerdfont.vim",
      "lambdalisue/glyph-palette.vim",
      {
        "TheLeoP/fern-renderer-web-devicons.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
      },
    },
  },

  -- インデントとブランクライン表示
  {
    "lukas-reineke/indent-blankline.nvim",
    event = "BufRead",
    main = "ibl",
  },

  -- その他のUI関連
  {
    "j-hui/fidget.nvim",
    event = "LspAttach",
    config = true,
  },
  {
    "norcalli/nvim-colorizer.lua",
    ft = { "css", "html", "javascript", "typescript", "lua" },
  },

  -- Snacks.nvim (総合UIプラグイン)
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    dependencies = {
      "echasnovski/mini.icons",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      local snacks = require("snacks")

      snacks.setup({
        bigfile = { enabled = true },
        dashboard = { enabled = true },
        explorer = { enabled = true },
        indent = { enabled = true },
        input = { enabled = true },
        notifier = {
          enabled = true,
          timeout = 3000,
        },
        picker = { enabled = true },
        quickfile = { enabled = true },
        scope = { enabled = true },
        scroll = { enabled = true },
        statuscolumn = { enabled = true },
        words = { enabled = true },
        image = { enabled = true, backend = "wezterm", inline_images = true },
        styles = {
          notification = {},
        },
      })

      -- xcodebuild用のプレビュー機能へのマッピング
      vim.keymap.set(
        "n",
        "<leader>xp",
        "<cmd>XcodebuildPreviewGenerateAndShow<CR>",
        { desc = "Generate & Show Preview" }
      )
      vim.keymap.set(
        "n",
        "<leader>xh",
        "<cmd>XcodebuildPreviewGenerateAndShow hotReload<CR>",
        { desc = "Generate Preview with Hot Reload" }
      )
    end,
  },
}