return {
  -- カラースキーム
  {
    "sainnhe/gruvbox-material",
    priority = 1000,
    config = function()
      vim.g.gruvbox_material_diagnostic_text_highlight = 1
      vim.g.gruvbox_material_diagnostic_line_highlight = 0
      vim.g.gruvbox_material_diagnostic_virtual_text = "colored"
      vim.g.gruvbox_material_current_word = "underline"
      vim.g.gruvbox_material_statusline_style = "mix"
      vim.g.gruvbox_material_transparent_background = 2
      vim.cmd.colorscheme("gruvbox-material")
    end,
  },
  {
    "sainnhe/everforest",
    lazy = true,
  },

  -- ステータスラインとタブ管理
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local xcodebuild_device = function()
        local platform = vim.g.xcodebuild_platform or ""
        local device = vim.g.xcodebuild_device_name or ""
        if device == "" then
          return ""
        end
        local icons = {
          iOS = "",
          iPadOS = "",
          macOS = "",
          watchOS = "",
          tvOS = "󰟴",
          visionOS = "󰿄",
        }
        return (icons[platform] or "") .. " " .. device
      end
      require("lualine").setup({
        options = {
          theme = "auto",
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
        },
        sections = {
          lualine_x = {
            {
              xcodebuild_device,
              cond = function()
                return vim.bo.filetype == "swift"
              end,
            },
            "encoding",
            "fileformat",
            "filetype",
          },
        },
      })
    end,
  },
  {
    "zefei/vim-wintabs",
    event = "VeryLazy",
    init = function()
      vim.keymap.set("n", "<C-e>c", "<Plug>(wintabs_close)")
      vim.keymap.set("n", "<C-k>", "<cmd>WintabsNext<CR>", { silent = true })
      vim.keymap.set("n", "<C-j>", "<cmd>WintabsPrevious<CR>", { silent = true })
      vim.keymap.set("n", "gt", "<cmd>WintabsNext<CR>", { silent = true })
      vim.keymap.set("n", "gT", "<cmd>WintabsPrevious<CR>", { silent = true })
    end,
  },
  {
    "zefei/vim-wintabs-powerline",
    event = "VeryLazy",
    dependencies = { "zefei/vim-wintabs" },
  },

  -- ファイルエクスプローラー
  {
    "stevearc/oil.nvim",
    cmd = "Oil",
    keys = {
      { "<Leader>dir", "<CMD>Oil<CR>", desc = "Open file explorer" },
      { "-", "<CMD>Oil<CR>", desc = "Open parent directory" },
    },
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      default_file_explorer = true,
      delete_to_trash = true,
      view_options = {
        show_hidden = true,
      },
      keymaps = {
        ["q"] = "actions.close",
        ["<C-s>"] = false, -- 既存のキーマップと競合回避
        ["<C-v>"] = "actions.select_vsplit",
      },
    },
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
    config = true,
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
        explorer = { enabled = false },
        indent = { enabled = true },
        input = { enabled = true },
        notifier = {
          enabled = true,
          timeout = 3000,
        },
        picker = { enabled = false },
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
    end,
  },
}
