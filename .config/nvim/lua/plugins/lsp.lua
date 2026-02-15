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
				auto_update = true,
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
			require("mason-lspconfig").setup({
				automatic_enable = true, -- Masonでインストール済みのLSPを自動有効化
			})

			-- カスタム設定が必要なLSPのみ記述
			vim.lsp.config("gopls", {
				settings = {
					gopls = {
						analyses = { unusedparams = true, shadow = true },
						staticcheck = true,
					},
				},
			})
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
			filewatching = "auto",
			broad_search = true,
		},
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
		cmd = { "Trouble" },
		dependencies = { "nvim-tree/nvim-web-devicons" },
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
		config = function()
			require("conform").setup({
				formatters_by_ft = {
					go = { "goimports", "gofmt" },
					python = { "ruff_format", "ruff_organize_imports" },
					cs = { "csharpier" },
					swift = { "swiftformat" },
				},
				formatters = {
					csharpier = {
						command = vim.fn.expand("~/.dotnet/tools/csharpier"),
						args = { "format", "--write-stdout" },
						stdin = true,
					},
				},
				format_on_save = {
					timeout_ms = 500,
					lsp_fallback = true,
				},
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
