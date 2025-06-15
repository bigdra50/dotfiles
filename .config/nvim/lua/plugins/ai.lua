return {
  -- Avante.nvim AI integration
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    lazy = false,
    version = false,
    build = "make",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "echasnovski/mini.pick",
      "nvim-telescope/telescope.nvim",
      "hrsh7th/nvim-cmp",
      "ibhagwan/fzf-lua",
      "nvim-tree/nvim-web-devicons",
      {
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
            use_absolute_path = true,
          },
        },
      },
      {
        "MeanderingProgrammer/render-markdown.nvim",
        opts = {
          file_types = { "markdown", "Avante" },
        },
        ft = { "markdown", "Avante" },
      },
    },
    config = function()
      require("avante").setup({
        provider = "claude",
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
        providers = {
          claude = {
            model = "claude-3-7-sonnet-20250219",
            timeout = 30000,
            extra_request_body = {
              max_tokens = 8000,
            },
          },
          openai = {
            model = "gpt-4o",
            timeout = 30000,
            extra_request_body = {
              max_tokens = 4096,
            },
          },
        },
      })
    end,
  },

  -- Markdown rendering enhancement
  {
    "MeanderingProgrammer/markdown.nvim",
    name = "render-markdown",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    ft = { "markdown", "Avante" },
    config = function()
      require("render-markdown").setup({
        file_types = { "markdown", "Avante" },
      })
    end,
  },
}