return {
  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "TSUpdateSync" },
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "lua",
          "vim",
          "vimdoc",
          "javascript",
          "typescript",
          "html",
          "css",
          "json",
          "yaml",
          "markdown",
          "markdown_inline",
          "swift",
          "python",
          "go",
          "rust",
          "bash",
          "dockerfile",
          "gitignore",
          "c_sharp",
        },
        sync_install = false,
        auto_install = true,
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
    keys = {
      { "<leader>ff", function() require("telescope.builtin").find_files() end, desc = "Find files" },
      { "<leader>fg", function() require("telescope.builtin").live_grep() end, desc = "Live grep" },
      { "<leader>fb", function() require("telescope.builtin").buffers() end, desc = "Buffers" },
      { "<leader>fh", function() require("telescope.builtin").help_tags() end, desc = "Help tags" },
    },
    config = function()
      require("telescope").setup({
        defaults = {
          file_ignore_patterns = { "%.meta$" },
          mappings = {
            i = {
              ["<C-u>"] = false,
              ["<C-d>"] = false,
            },
          },
        },
      })
    end,
  },

  -- オートペア、タグ、サラウンド
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {
      disable_filetype = { "TelescopePrompt", "vim" },
    },
  },
  {
    "windwp/nvim-ts-autotag",
    event = "InsertEnter",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = true,
  },
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    config = true,
  },

  -- 検索ハイライト強化
  {
    "kevinhwang91/nvim-hlslens",
    keys = { "/", "?", "*", "#", "n", "N" },
    config = function()
      require("hlslens").setup({
        calm_down = true,
        nearest_only = true,
      })
      local opts = { noremap = true, silent = true }
      vim.keymap.set("n", "n", [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]], opts)
      vim.keymap.set("n", "N", [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]], opts)
      vim.keymap.set("n", "*", [[*<Cmd>lua require('hlslens').start()<CR>]], opts)
      vim.keymap.set("n", "#", [[#<Cmd>lua require('hlslens').start()<CR>]], opts)
      vim.keymap.set("n", "g*", [[g*<Cmd>lua require('hlslens').start()<CR>]], opts)
      vim.keymap.set("n", "g#", [[g#<Cmd>lua require('hlslens').start()<CR>]], opts)
    end,
  },
  {
    "simeji/winresizer",
    cmd = "WinResizerStartResize",
  },
  {
    "rmagatti/auto-session",
    lazy = false,
    config = function()
      local path_utils = require("utils.path")
      require("auto-session").setup({
        log_level = "error",
        auto_session_suppress_dirs = {
          path_utils.home(),
          path_utils.join(path_utils.home(), "Projects"),
          path_utils.join(path_utils.home(), "Downloads"),
          "/",
        },
      })
    end,
  },

  -- デバッグ
  {
    "mfussenegger/nvim-dap",
    keys = { "<F5>", "<F10>", "<F11>", "<F12>" },
    config = function()
      local dap = require("dap")
      local xcodebuild_dap = require("xcodebuild.integrations.dap")
      xcodebuild_dap.setup()

      require("utils.signs").setup_dap()

      vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Continue" })
      vim.keymap.set("n", "<leader>dC", dap.run_to_cursor, { desc = "Run To Cursor" })
      vim.keymap.set("n", "<leader>ds", dap.step_over, { desc = "Step Over" })
      vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Step Into" })
      vim.keymap.set("n", "<leader>do", dap.step_out, { desc = "Step Out" })
      vim.keymap.set({ "n", "v" }, "<leader>dh", require("dap.ui.widgets").hover, { desc = "Hover" })
      vim.keymap.set({ "n", "v" }, "<leader>de", function()
        local ok, dapui = pcall(require, "dapui")
        if ok then dapui.eval() end
      end, { desc = "Eval" })

      vim.keymap.set("n", "<leader>dd", xcodebuild_dap.build_and_debug, { desc = "Build & Debug" })
      vim.keymap.set("n", "<leader>dr", xcodebuild_dap.debug_without_build, { desc = "Debug Without Building" })
      vim.keymap.set("n", "<leader>dt", xcodebuild_dap.debug_tests, { desc = "Debug Tests" })
      vim.keymap.set("n", "<leader>dT", xcodebuild_dap.debug_class_tests, { desc = "Debug Class Tests" })
      vim.keymap.set("n", "<leader>b", xcodebuild_dap.toggle_breakpoint, { desc = "Toggle Breakpoint" })
      vim.keymap.set("n", "<leader>B", xcodebuild_dap.toggle_message_breakpoint, { desc = "Toggle Message Breakpoint" })
      vim.keymap.set("n", "<leader>dx", function()
        xcodebuild_dap.terminate_session()
        dap.listeners.after["event_terminated"]["me"]()
      end, { desc = "Terminate debugger" })
    end,
  },
  {
    "rcarriga/nvim-dap-ui",
    keys = { "<F5>", "<F10>", "<F11>", "<F12>" },
    dependencies = {
      "nvim-dap",
      "nvim-neotest/nvim-nio",
    },
    config = function()
      local dapui = require("dapui")
      dapui.setup({
        controls = {
          element = "repl",
          enabled = true,
          icons = {
            disconnect = "",
            run_last = "",
            terminate = "⏹︎",
            pause = "⏸︎",
            play = "",
            step_into = "󰆹",
            step_out = "󰆸",
            step_over = "",
            step_back = "",
          },
        },
        floating = {
          border = "single",
          mappings = { close = { "q", "<Esc>" } },
        },
        icons = {
          collapsed = "",
          expanded = "",
          current_frame = "",
        },
        layouts = {
          {
            elements = {
              { id = "stacks", size = 0.25 },
              { id = "scopes", size = 0.25 },
              { id = "breakpoints", size = 0.25 },
              { id = "watches", size = 0.25 },
            },
            position = "left",
            size = 40,
          },
          {
            elements = {
              { id = "repl", size = 0.4 },
              { id = "console", size = 0.6 },
            },
            position = "bottom",
            size = 10,
          },
        },
      })

      local dap = require("dap")
      local group = vim.api.nvim_create_augroup("dapui_config", { clear = true })
      vim.api.nvim_create_autocmd("BufWinEnter", {
        group = group,
        pattern = { "DAP*", "\\[dap\\-repl\\]" },
        callback = function()
          vim.wo.fillchars = "eob: "
        end,
      })
      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
    end,
  },

  -- Git 統合
  {
    "aspeddro/gitui.nvim",
    cmd = "Gitui",
    opts = {
      window = {
        options = {
          width = 90,
          height = 80,
          border = "rounded",
        },
      },
    },
  },
  {
    "tpope/vim-fugitive",
    cmd = { "Git", "Gdiff", "Gstatus", "Gblame", "Gvdiffsplit" },
    keys = {
      { "<leader>b", "<cmd>Git blame<CR>", desc = "Git blame" },
      { "<leader>d", "<cmd>Gvdiffsplit<CR>", desc = "Git diff" },
      { "<leader>l", "<cmd>Git log --graph<CR><C-w>T", desc = "Git log" },
    },
  },
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("gitsigns").setup({
        signs = {
          add = { text = "│" },
          change = { text = "│" },
          delete = { text = "_" },
          topdelete = { text = "‾" },
          changedelete = { text = "~" },
          untracked = { text = "┆" },
        },
        signs_staged = {
          add = { text = "│" },
          change = { text = "│" },
          delete = { text = "_" },
          topdelete = { text = "‾" },
          changedelete = { text = "~" },
          untracked = { text = "┆" },
        },
        on_attach = function(bufnr)
          local gs = require("gitsigns")
          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end
          map("n", "g]", function()
            if vim.wo.diff then return "g]" end
            vim.schedule(function() gs.next_hunk() end)
            return "<Ignore>"
          end, { expr = true })
          map("n", "g[", function()
            if vim.wo.diff then return "g[" end
            vim.schedule(function() gs.prev_hunk() end)
            return "<Ignore>"
          end, { expr = true })
          map("n", "gu", gs.reset_hunk)
          map("n", "gp", gs.preview_hunk)
          map("n", "gh", gs.toggle_linehl)
        end,
      })
    end,
  },

  -- ファイルタイプ固有
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
      local progress_handle
      require("xcodebuild").setup({
        show_build_progress_bar = false,
        integrations = {
          oil_nvim = { enabled = true },
          pymobiledevice = { enabled = true },
        },
        logs = {
          auto_open_on_success_tests = false,
          auto_open_on_failed_tests = false,
          auto_open_on_success_build = false,
          auto_open_on_failed_build = false,
          auto_focus = false,
          auto_close_on_app_launch = true,
          only_summary = true,
          notify = function(message, severity)
            local fidget = require("fidget")
            if progress_handle then
              progress_handle.message = message
              if not message:find("Loading") then
                progress_handle:finish()
                progress_handle = nil
                if vim.trim(message) ~= "" then
                  fidget.notify(message, severity)
                end
              end
            else
              fidget.notify(message, severity)
            end
          end,
          notify_progress = function(message)
            local progress = require("fidget.progress")
            if progress_handle then
              progress_handle.title = ""
              progress_handle.message = message
            else
              progress_handle = progress.handle.create({
                message = message,
                lsp_client = { name = "xcodebuild.nvim" },
              })
            end
          end,
        },
        code_coverage = { enabled = true },
      })

      vim.keymap.set("n", "<leader>X", "<cmd>XcodebuildPicker<cr>", { desc = "Show Xcodebuild Actions" })
      vim.keymap.set("n", "<leader>xf", "<cmd>XcodebuildProjectManager<cr>", { desc = "Show Project Manager Actions" })
      vim.keymap.set("n", "<leader>xb", "<cmd>XcodebuildBuild<cr>", { desc = "Build Project" })
      vim.keymap.set("n", "<leader>xB", "<cmd>XcodebuildBuildForTesting<cr>", { desc = "Build For Testing" })
      vim.keymap.set("n", "<leader>xr", "<cmd>XcodebuildBuildRun<cr>", { desc = "Build & Run Project" })
      vim.keymap.set("n", "<leader>xt", "<cmd>XcodebuildTest<cr>", { desc = "Run Tests" })
      vim.keymap.set("v", "<leader>xt", "<cmd>XcodebuildTestSelected<cr>", { desc = "Run Selected Tests" })
      vim.keymap.set("n", "<leader>xT", "<cmd>XcodebuildTestClass<cr>", { desc = "Run This Test Class" })
      vim.keymap.set("n", "<leader>xl", "<cmd>XcodebuildToggleLogs<cr>", { desc = "Toggle Xcodebuild Logs" })
      vim.keymap.set("n", "<leader>xc", "<cmd>XcodebuildToggleCodeCoverage<cr>", { desc = "Toggle Code Coverage" })
      vim.keymap.set("n", "<leader>xC", "<cmd>XcodebuildShowCodeCoverageReport<cr>", { desc = "Show Code Coverage Report" })
      vim.keymap.set("n", "<leader>xe", "<cmd>XcodebuildTestExplorerToggle<cr>", { desc = "Toggle Test Explorer" })
      vim.keymap.set("n", "<leader>xs", "<cmd>XcodebuildFailingSnapshots<cr>", { desc = "Show Failing Snapshots" })
      vim.keymap.set("n", "<leader>xd", "<cmd>XcodebuildSelectDevice<cr>", { desc = "Select Device" })
      vim.keymap.set("n", "<leader>xp", "<cmd>XcodebuildSelectTestPlan<cr>", { desc = "Select Test Plan" })
      vim.keymap.set("n", "<leader>xq", "<cmd>Telescope quickfix<cr>", { desc = "Show QuickFix List" })
      vim.keymap.set("n", "<leader>xx", "<cmd>XcodebuildQuickfixLine<cr>", { desc = "Quickfix Line" })
      vim.keymap.set("n", "<leader>xa", "<cmd>XcodebuildCodeActions<cr>", { desc = "Show Code Actions" })
    end,
  },
}
