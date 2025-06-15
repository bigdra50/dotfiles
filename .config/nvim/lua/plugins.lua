local status, packer = pcall(require, "packer")
if not status then
  print("Packer is not installed")
  return
end

vim.cmd([[packadd packer.nvim]])

packer.startup(function(use)
  -- Packer 自体の管理
  use("wbthomason/packer.nvim")

  -- 共通依存ライブラリ
  use("nvim-lua/plenary.nvim") -- Common utilities

  -- カラースキーム
  use("sainnhe/gruvbox-material")
  use("rose-pine/neovim")
  use("sainnhe/everforest")
  use("folke/lsp-colors.nvim")

  -- インデントとブランクライン表示
  use("lukas-reineke/indent-blankline.nvim")

  -- カーソルホールドの修正
  use("antoinemadec/FixCursorHold.nvim")

  -- ステータスラインとタブ管理
  use("nvim-lualine/lualine.nvim") -- Statusline
  use("zefei/vim-wintabs")
  use("zefei/vim-wintabs-powerline")

  -- ファイルエクスプローラーとアイコン
  use("lambdalisue/fern.vim")
  use("lambdalisue/nerdfont.vim")
  use("lambdalisue/fern-renderer-nerdfont.vim")
  use({
    "TheLeoP/fern-renderer-web-devicons.nvim",
    requires = {
      "nvim-tree/nvim-web-devicons",
    },
  })
  use("lambdalisue/glyph-palette.vim")

  -- LSPと補完
  use({
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "neovim/nvim-lspconfig",
  })
  use({
    "hrsh7th/nvim-cmp",
    --event = 'InsertEnter'
  })
  use("hrsh7th/cmp-nvim-lsp")
  use("hrsh7th/cmp-vsnip")
  use("hrsh7th/cmp-buffer") -- source for text in buffer
  use("hrsh7th/cmp-path") -- source for file system paths
  use("L3MON4D3/LuaSnip") -- snippet engine
  use("saadparwaiz1/cmp_luasnip") -- for autocompletion
  use("rafamadriz/friendly-snippets") -- useful snippets
  use("onsails/lspkind.nvim") -- vs-code like pictograms
  use("hrsh7th/cmp-cmdline")
  use("hrsh7th/cmp-nvim-lsp-signature-help")
  use("hrsh7th/vim-vsnip")
  use("glepnir/lspsaga.nvim")
  use({
    "folke/trouble.nvim",
    requires = {
      "nvim-tree/nvim-web-devicons",
    },
    --event = { "BufReadPre", "BufNewFile" },
  })

  use("mfussenegger/nvim-dap")
  use({
    "rcarriga/nvim-dap-ui",
    requires = {
      "mfussenegger/nvim-dap",
      "nvim-neotest/nvim-nio",
    },
  })

  use({
    "wojciech-kulik/xcodebuild.nvim",
    requires = {
      "nvim-telescope/telescope.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-treesitter/nvim-treesitter", -- (オプション) クイックテストサポート用（Swiftパーサーが必要）
    },
    config = function()
      require("xcodebuild").setup({
        -- ここにオプションを追加するか、デフォルト設定を使用する場合は空のままにします
      })
    end,
  })

  -- Treesitter
  use({
    "nvim-treesitter/nvim-treesitter",
    run = function()
      require("nvim-treesitter.install").update({ with_sync = true })
    end,
  })

  -- ファイルタイプ固有のプラグイン
  use("digitaltoad/vim-pug")
  use({
    "iamcco/markdown-preview.nvim",
    run = "cd app && npm install",
    setup = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
    ft = { "markdown" },
  })

  use({
    "MeanderingProgrammer/markdown.nvim",
    as = "render-markdown", -- Only needed if you have another plugin named markdown.nvim
    after = { "nvim-treesitter" },
    requires = { "echasnovski/mini.nvim", opt = true }, -- if you use the mini.nvim suite
    -- requires = { 'echasnovski/mini.icons', opt = true }, -- if you use standalone mini plugins
    -- requires = { 'nvim-tree/nvim-web-devicons', opt = true }, -- if you prefer nvim-web-devicons
    config = function()
      require("render-markdown").setup({})
    end,
  })

  -- Linterとフォーマッター
  use({
    "nvimtools/none-ls.nvim",
    requires = { "nvim-lua/plenary.nvim", "nvimtools/none-ls-extras.nvim" },
  })

  use({
    "jay-babu/mason-null-ls.nvim",
    requires = {
      "williamboman/mason.nvim",
      "nvimtools/none-ls.nvim",
    },
    --event = { "BufReadPre", "BufNewFile" },
  })
  use({
    "stevearc/conform.nvim"
  })
  use({
    "zapling/mason-conform.nvim",
    after = { "mason.nvim", "conform.nvim" }
  })

  use("j-hui/fidget.nvim")

  -- ファジーファインダーと拡張機能
  use("nvim-telescope/telescope.nvim")
  use({
    "nvim-telescope/telescope-frecency.nvim",
    requires = { "kkharji/sqlite.lua" },
  })

  -- オートペア、タグ、コメント、サラウンド機能
  use("windwp/nvim-autopairs")
  use("windwp/nvim-ts-autotag")
  use("terrortylor/nvim-comment")
  use("kylechui/nvim-surround")
  use("machakann/vim-highlightedyank")

  -- その他のユーティリティ
  use("kevinhwang91/nvim-hlslens")
  use("norcalli/nvim-colorizer.lua")
  use("simeji/winresizer")
  use("rmagatti/auto-session")

  -- Git 統合
  use("aspeddro/gitui.nvim")
  use("kdheepak/lazygit.nvim") -- TODO: gituiのテストが済んだらlazygitは削除する
  use("tpope/vim-fugitive")
  use("lewis6991/gitsigns.nvim")
  use({ "airblade/vim-gitgutter", branch = "main" })

  -- その他のプラグイン
  use("github/copilot.vim")

  --  -- avante.nvim

  --  --- Required plugins
  --  use("stevearc/dressing.nvim")
  --  use("MunifTanjim/nui.nvim")
  --  use("MeanderingProgrammer/render-markdown.nvim")

  --  --- Optional dependencies
  --  use("nvim-tree/nvim-web-devicons") -- or use 'echasnovski/mini.icons'
  --  use("HakonHarnes/img-clip.nvim")
  --  use("zbirenbaum/copilot.lua")

  --  --- Avante.nvim with build process
  --  use({
  --    "yetone/avante.nvim",
  --    branch = "main",
  --    run = "make",
  --    config = function()
  --      require("avante_lib").load()
  --      require("avante").setup()
  --    end,
  --  })

  use({
    "folke/snacks.nvim",
    requires = {
      -- オプションの依存関係
      "echasnovski/mini.icons", -- オプション
      "nvim-tree/nvim-web-devicons", -- オプション
    },
    config = function()
      -- snacks.nvimの基本セットアップ
      local snacks = require("snacks")

      snacks.setup({
        -- プラグインの設定
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
        -- xcodebuild.nvimで必要なimage機能を有効に
        image = { enabled = true, backend = "wezterm", inline_images = true },
        styles = {
          notification = {
            -- wo = { wrap = true } -- 通知を折り返し表示
          },
        },
      })

      -- キーマッピングは必要に応じて追加
      -- 例: xcodebuild用のプレビュー機能へのマッピング
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

      -- その他の設定やキーマッピングを追加
    end,
  })

  use({
    "yetone/avante.nvim",
    requires = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      --- オプションの依存関係
      "echasnovski/mini.pick", -- file_selector provider mini.pick用
      "nvim-telescope/telescope.nvim", -- file_selector provider telescope用
      "hrsh7th/nvim-cmp", -- avante commandsとmentions用のオートコンプリート
      "ibhagwan/fzf-lua", -- file_selector provider fzf用
      "nvim-tree/nvim-web-devicons", -- または echasnovski/mini.icons
      "zbirenbaum/copilot.lua", -- providers='copilot'用
      {
        -- 画像貼り付けサポート
        "HakonHarnes/img-clip.nvim",
        config = function()
          require("img-clip").setup({
            -- 推奨設定
            default = {
              embed_image_as_base64 = false,
              prompt_for_file_name = false,
              drag_and_drop = {
                insert_mode = true,
              },
              -- Windows ユーザーには必須
              use_absolute_path = true,
            },
          })
        end,
      },
      {
        "MeanderingProgrammer/render-markdown.nvim",
        config = function()
          require("render-markdown").setup({
            file_types = { "markdown", "Avante" },
          })
        end,
        ft = { "markdown", "Avante" },
      },
    },
    run = "make", -- ソースからビルドする場合は `make BUILD_FROM_SOURCE=true` に変更
    -- Windows用: run = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
    config = function()
      require("avante").setup({
        -- provider = "copilot",
        provider = "claude",
        -- provider = "openai",
        auto_suggestions_provider = "claude",
        behaviour = {
          auto_suggestions = true,
          auto_set_highlight_group = true,
          auto_set_keymaps = true,
          auto_apply_diff_after_generation = true,
          support_paste_from_clipboard = true,
        },
        windows = {
          position = "right",
          width = 30,
          sidebar_header = {
            align = "center",
            rounded = false,
          },
          ask = {
            floating = true,
            start_insert = true,
            border = "rounded",
          },
        },
        -- providers-setting
        claude = {
          model = "claude-3-7-sonnet-20250219", --
          -- model = "claude-3-5-sonnet-20240620", -- $3/$15, maxtokens=8000
          -- model = "claude-3-opus-20240229",  -- $15/$75
          -- model = "claude-3-haiku-20240307", -- $0.25/1.25
          max_tokens = 8000,
        },
        copilot = {
          model = "gpt-4o-2024-05-13",
          -- model = "gpt-4o-mini",
          max_tokens = 4096,
        },
        openai = {
          model = "gpt-4o", -- $2.5/$10
          -- model = "gpt-4o-mini", -- $0.15/$0.60
          max_tokens = 4096,
        },
      })
    end,
  })
end)