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
			})
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			-- カスタム設定が必要なLSPのみ記述
			local server_settings = {
				gopls = {
					settings = {
						gopls = {
							analyses = { unusedparams = true, shadow = true },
							staticcheck = true,
						},
					},
				},
			}

			require("mason-lspconfig").setup({
				ensure_installed = {},
				handlers = {
					function(server_name)
						local opts = server_settings[server_name] or {}
						require("lspconfig")[server_name].setup(opts)
					end,
				},
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		lazy = true,
	},

	-- LSP UI強化
	{
		"nvimdev/lspsaga.nvim",
		event = "LspAttach",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
	},
	{
		"folke/trouble.nvim",
		cmd = { "Trouble", "TroubleToggle" },
		dependencies = { "nvim-tree/nvim-web-devicons" },
	},

	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		config = function()
			require("conform").setup({
				formatters_by_ft = {
					go = { "goimports", "gofmt" },
				},
				format_on_save = {
					timeout_ms = 500,
					lsp_fallback = true,
				},
			})
		end,
	},
	{
		"zapling/mason-conform.nvim",
		dependencies = { "williamboman/mason.nvim", "stevearc/conform.nvim" },
		config = function()
			require("mason-conform").setup({
				ignore_install = { "swift-format" }, -- Mac組み込みのswift-formatを使用するため
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
			"hrsh7th/cmp-vsnip",
			"hrsh7th/vim-vsnip",
			"saadparwaiz1/cmp_luasnip",
			"onsails/lspkind.nvim",
		},
	},

	-- コマンドライン補完（独立設定）
	{
		"hrsh7th/cmp-cmdline",
		lazy = false, -- 起動時に読み込み
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

