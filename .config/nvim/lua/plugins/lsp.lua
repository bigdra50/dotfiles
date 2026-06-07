return {
  -- Mason (LSPサーバー管理)
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate", "MasonLog" },
    config = function()
      require("mason").setup({
        ui = {
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
          },
        },
        -- Roslyn LSP用カスタムレジストリ
        registries = {
          "github:mason-org/mason-registry",
          "github:Crashdummyy/mason-registry",
        },
      })
    end,
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-tool-installer").setup({
        ensure_installed = {
          "bash-language-server",
          "csharpier",
          "goimports",
          "gopls",
          "jsonlint",
          "netcoredbg",
          "prettier",
          "pyright",
          "ruff",
          "stylua",
        },
        auto_update = false,
        run_on_start = true,
        start_delay = 3000, -- 3秒遅延
        debounce_hours = 24, -- 24時間に1回
      })
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local cmp_nvim_lsp = require("cmp_nvim_lsp")
      local capabilities = cmp_nvim_lsp.default_capabilities()

      require("mason-lspconfig").setup({
        automatic_enable = true,
      })

      -- LSP共通の on_attach（Lspsaga が K, gd, rn を担当するため、ここでは補助的な設定のみ）
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local bufnr = args.buf
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          vim.keymap.set("n", "gl", vim.diagnostic.open_float, { buffer = bufnr, desc = "Show line diagnostics" })
          vim.keymap.set("n", "<leader>i", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ 0 }), { 0 })
          end, { buffer = bufnr, desc = "Toggle inlay hints" })
          vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"

          if client and client.name == "gopls" then
            vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
          end
        end,
      })

      -- gopls
      vim.lsp.config("gopls", {
        capabilities = capabilities,
        settings = {
          gopls = {
            analyses = { unusedparams = true, shadow = true },
            staticcheck = true,
            gofumpt = true,
            usePlaceholders = true,
            completeUnimported = true,
            vulncheck = "Imports",
            hints = {
              assignVariableTypes = true,
              compositeLiteralFields = true,
              compositeLiteralTypes = true,
              constantValues = true,
              functionTypeParameters = true,
              parameterNames = true,
              rangeVariableTypes = true,
            },
          },
        },
      })

      -- sourcekit (Swift)
      vim.lsp.config("sourcekit", {
        capabilities = capabilities,
        filetypes = { "swift", "objective-c", "objective-cpp", "c", "cpp" },
        root_markers = { "Package.swift", ".git" },
      })
      vim.lsp.enable("sourcekit")

      -- UPM LSP (Unity Package Manager manifest.json)
      vim.lsp.config("upm_lsp", {
        cmd = { "npx", "--yes", "github:bigdra50/upm-lsp", "--stdio" },
        filetypes = { "json" },
        root_markers = { "Packages/manifest.json", "Assets" },
        capabilities = capabilities,
      })
      vim.lsp.enable("upm_lsp")

      -- 診断サイン
      require("utils.signs").setup_diagnostics()

      -- lsp-file-operations
      local ok, lsp_file_ops = pcall(require, "lsp-file-operations")
      if ok then
        lsp_file_ops.setup()
      end
    end,
  },
  {
    "neovim/nvim-lspconfig",
    lazy = true,
  },

  -- Roslyn LSP (C#)
  {
    "seblyng/roslyn.nvim",
    ft = { "cs", "razor" },
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      filewatching = "off",
      broad_search = true,
    },
    init = function()
      -- Unity プロジェクトの .csproj が未インストールの Unity バージョンを参照している場合、
      -- インストール済みバージョンにフォールバックする
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "cs", "razor" },
        once = true,
        callback = function()
          local root = vim.fs.root(0, "ProjectSettings")
          if not root then
            return
          end
          local version_file = root .. "/ProjectSettings/ProjectVersion.txt"
          if vim.fn.filereadable(version_file) ~= 1 then
            return
          end
          local script = vim.fn.expand("~/dev/github.com/bigdra50/dotfiles/scripts/unity-fix-csproj.sh")
          if vim.fn.executable(script) == 1 then
            vim.fn.system({ script, root })
          end
        end,
      })
    end,
  },

  -- LSP UI強化
  {
    "nvimdev/lspsaga.nvim",
    event = "LspAttach",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("lspsaga").setup({
        ui = {
          border = "rounded",
          winblend = 6,
          code_action = "💡",
        },
        lightbulb = { enable = false },
        symbol_in_winbar = { enable = false },
        finder = {
          edit = { "o", "<CR>" },
          vsplit = "s",
          split = "i",
          tabe = "t",
          quit = { "q", "<ESC>" },
        },
        diagnostic = {
          show_code_action = false,
          show_source = true,
        },
      })
      local keymap = vim.keymap.set
      keymap("n", "gf", "<cmd>Lspsaga finder<CR>", { silent = true })
      keymap("n", "gd", "<cmd>Lspsaga goto_definition<CR>", { silent = true })
      keymap("n", "<C-]>", "<cmd>Lspsaga goto_definition<CR>", { silent = true })
      keymap("n", "<C-T>", "<C-o>", { silent = true })
      keymap("n", "rn", "<cmd>Lspsaga rename<CR>", { silent = true })
      keymap("n", "K", "<cmd>Lspsaga hover_doc<CR>", { silent = true })
      keymap("n", "<space>e", "<cmd>Lspsaga show_line_diagnostics<CR>", { silent = true })
      keymap("n", "g[", "<cmd>Lspsaga diagnostic_jump_prev<CR>", { silent = true })
      keymap("n", "g]", "<cmd>Lspsaga diagnostic_jump_next<CR>", { silent = true })
    end,
  },
  {
    "folke/trouble.nvim",
    cmd = { "Trouble" },
    keys = {
      { "<leader>tt", "<cmd>Trouble quickfix toggle<cr>", desc = "Open a quickfix" },
    },
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("trouble").setup({
        auto_open = false,
        auto_close = false,
        auto_preview = true,
        auto_jump = {},
        mode = "quickfix",
        severity = vim.diagnostic.severity.ERROR,
        cycle_results = false,
      })
      vim.api.nvim_create_autocmd("User", {
        pattern = { "XcodebuildBuildFinished", "XcodebuildTestsFinished" },
        callback = function(event)
          if event.data.cancelled then
            return
          end
          local trouble = require("trouble")
          if event.data.success then
            trouble.close()
          elseif not event.data.failedCount or event.data.failedCount > 0 then
            if next(vim.fn.getqflist()) then
              trouble.open({ focus = false })
            else
              trouble.close()
            end
            trouble.refresh()
          end
        end,
      })
    end,
  },

  -- Linter
  {
    "mfussenegger/nvim-lint",
    event = { "BufWritePost", "BufReadPost", "InsertLeave" },
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = {
        json = { "jsonlint" },
        swift = { "swiftlint" },
      }
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
        callback = function()
          lint.try_lint()
        end,
      })
    end,
  },

  -- Formatter
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>fmt",
        function()
          require("conform").format({ lsp_fallback = true, async = false, timeout_ms = 500 })
        end,
        mode = { "n", "v" },
        desc = "Format file or range",
      },
    },
    config = function()
      local path_utils = require("utils.path")
      require("conform").setup({
        formatters_by_ft = {
          go = { "goimports", "gofmt" },
          python = { "ruff_format", "ruff_organize_imports" },
          cs = { "csharpier" },
          swift = { "swiftformat" },
          haskell = { "fourmolu" },
          lua = { "stylua" },
          javascript = { "prettier" },
          typescript = { "prettier" },
          javascriptreact = { "prettier" },
          typescriptreact = { "prettier" },
          css = { "prettier" },
          html = { "prettier" },
          json = { "prettier" },
          yaml = { "prettier" },
          markdown = { "prettier" },
        },
        formatters = {
          csharpier = {
            command = vim.fn.expand("~/.dotnet/tools/csharpier"),
            args = { "format", "--write-stdout" },
            stdin = true,
          },
        },
        format_on_save = function(bufnr)
          local ignore_filetypes = { "oil" }
          if vim.tbl_contains(ignore_filetypes, vim.bo[bufnr].filetype) then
            return
          end
          return { timeout_ms = 500, lsp_fallback = true }
        end,
      })
    end,
  },

  -- 補完システム
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-nvim-lsp-signature-help",
      "saadparwaiz1/cmp_luasnip",
      "onsails/lspkind.nvim",
    },
    config = function()
      local cmp = require("cmp")
      local lspkind = require("lspkind")
      vim.opt.completeopt = { "menu", "menuone", "noselect" }

      cmp.setup({
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
          { name = "nvim_lsp_signature_help" },
        }),
        mapping = cmp.mapping.preset.insert({
          ["<C-u>"] = cmp.mapping.scroll_docs(-4),
          ["<C-b>"] = cmp.mapping.scroll_docs(4),
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<CR>"] = cmp.mapping.confirm({ select = false, behavior = cmp.ConfirmBehavior.Replace }),
        }),
        experimental = { ghost_text = true },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        formatting = {
          format = lspkind.cmp_format({
            mode = "symbol",
            maxwidth = 50,
            ellipsis_char = "...",
          }),
        },
      })

      cmp.setup.cmdline("/", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = { { name = "buffer" } },
      })

      pcall(function()
        cmp.setup.cmdline(":", {
          mapping = {
            ["<Tab>"] = cmp.mapping(function()
              if cmp.visible() then
                cmp.confirm({ select = true })
              else
                cmp.complete()
              end
            end, { "c" }),
            ["<C-n>"] = cmp.mapping(cmp.mapping.select_next_item(), { "c" }),
            ["<C-p>"] = cmp.mapping(cmp.mapping.select_prev_item(), { "c" }),
          },
          sources = {
            { name = "cmdline", keyword_length = 1 },
            { name = "path", keyword_length = 1 },
          },
          completion = { autocomplete = { cmp.TriggerEvent.TextChanged } },
          preselect = cmp.PreselectMode.Item,
        })
      end)

      vim.cmd([[highlight! default link CmpItemKind CmpItemMenuDefault]])
    end,
  },

  -- コマンドライン補完（独立設定）
  {
    "hrsh7th/cmp-cmdline",
    event = "CmdlineEnter",
    dependencies = { "hrsh7th/nvim-cmp" },
  },

  -- スニペット
  {
    "L3MON4D3/LuaSnip",
    event = "InsertEnter",
    dependencies = { "rafamadriz/friendly-snippets" },
    build = "make install_jsregexp",
  },
}
