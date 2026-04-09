return {
  -- Haskell Tools (HLS integration)
  {
    "mrcjkb/haskell-tools.nvim",
    version = "^4",
    ft = { "haskell", "lhaskell", "cabal", "cabalproject" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
    },
    init = function()
      vim.g.haskell_tools = {
        hls = {
          on_attach = function(client, bufnr)
            local ht = require("haskell-tools")
            local opts = { buffer = bufnr, silent = true }

            vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
            vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
            vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
            vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
            vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

            vim.keymap.set("n", "<leader>hs", ht.hoogle.hoogle_signature, opts)
            vim.keymap.set("n", "<leader>he", ht.lsp.buf_eval_all, opts)
            vim.keymap.set("n", "<leader>hr", ht.repl.toggle, opts)
          end,
          settings = {
            haskell = {
              formattingProvider = "fourmolu",
              checkProject = true,
            },
          },
        },
        tools = {
          repl = {
            handler = "toggleterm",
            prefer = function()
              return vim.fn.executable("stack") == 1 and "stack" or "cabal"
            end,
          },
          hover = {
            enable = true,
            stylize_markdown = true,
          },
        },
      }
    end,
  },

  -- Toggle terminal (for REPL)
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    keys = { [[<c-\>]] },
    opts = {
      size = 20,
      open_mapping = [[<c-\>]],
      direction = "horizontal",
    },
  },
}
