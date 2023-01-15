--  https://github.com/nvim-lualine/lualine.nvim
require("lualine").setup({
  options = {
    icons_enabled = true,
    theme = "auto",
    component_separators = { left = "рт", right = "рф" },
    section_separators = { left = "рс", right = "ру" },
    disabled_filetypes = {},
    always_divide_middle = true,
    colored = true,
    globalstatus = true,
  },
  sections = {
    lualine_a = {
      "mode",
    },
    lualine_b = { "branch", "diff" },
    lualine_c = {
      {
        "filename",
        path = 1,
        file_status = true,
        shorting_target = 40,
        symbols = {
          modified = " [+]",
          readonly = " [RO]",
          unnamed = "Untitled",
        },
      },
    },
    lualine_x = { "filetype", "encoding" },
    lualine_y = {
      {
        "diagnostics",
        -- Table of diagnostic sources, available sources are:
        --   'nvim_lsp', 'nvim_diagnostic', 'nvim_workspace_diagnostic', 'coc', 'ale', 'vim_lsp'.
        -- or a function that returns a table as such:
        --   { error=error_cnt, warn=warn_cnt, info=info_cnt, hint=hint_cnt }
        sources = { "nvim_diagnostic", "coc" },

        -- Displays diagnostics for the defined severity types
        sections = { "error", "warn", "info", "hint" },

        diagnostics_color = {
          -- Same values as the general color option can be used here.
          error = "DiagnosticError", -- Changes diagnostics' error color.
          warn = "DiagnosticWarn", -- Changes diagnostics' warn color.
          info = "DiagnosticInfo", -- Changes diagnostics' info color.
          hint = "DiagnosticHint", -- Changes diagnostics' hint color.
        },
        symbols = { error = "E", warn = "W", info = "I", hint = "H" },
        colored = true, -- Displays diagnostics status in color if set to true.
        update_in_insert = false, -- Update diagnostics in insert mode.
        always_visible = true, -- Show diagnostics even if there are none.
      },
    },
    lualine_z = { "location" },
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = { "filename" },
    lualine_x = { "location" },
    lualine_y = {},
    lualine_z = {},
  },
  tabline = {
    lualine_a = {
      "buffers",
    },
    lualine_b = { "branch" },
    lualine_c = {},
    lualine_x = {},
    lualine_y = {},
    lualine_z = {
      "tabs",
    },
  },
  extensions = {},
})
