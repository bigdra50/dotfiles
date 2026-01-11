vim.cmd("autocmd!")

-- 特定の非推奨警告のみを無効化
local original_notify = vim.notify
vim.notify = function(msg, level, opts)
  if msg and msg:match("vim%.tbl_flatten is deprecated") then
    return -- tbl_flattenの警告のみを無視
  end
  return original_notify(msg, level, opts)
end

vim.scriptencoding = "utf-8"
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"
vim.opt.compatible = false
vim.opt.number = true
vim.opt.mouse = "a"
vim.opt.title = true
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.breakindent = true
vim.opt.hlsearch = true
vim.opt.backup = false
vim.opt.showcmd = true
vim.opt.cmdheight = 1
vim.opt.shortmess:append("I")  -- 起動メッセージを短縮
vim.opt.expandtab = true
vim.opt.scrolloff = 10
vim.opt.laststatus = 3
--vim.opt.shell = 'zsh'
vim.opt.inccommand = "split"
vim.opt.ignorecase = true
vim.opt.smarttab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.wrap = false
vim.opt.helplang = { "ja", "en" }
vim.opt.updatetime = 300
vim.opt.showtabline = 2
vim.opt.clipboard = "unnamedplus"
vim.opt.termguicolors = true
vim.opt.winblend = 0
vim.opt.pumblend = 0
vim.opt.signcolumn = "yes"
vim.opt.hidden = true
vim.opt.swapfile = false
vim.opt.pumblend = 7
vim.wo.relativenumber = true

-- nvim-cmp補完メニューの設定
vim.opt.pumheight = 15  -- 補完メニューの最大高さ
vim.opt.pumwidth = 30   -- 補完メニューの最小幅

-- 不可視文字を非表示(colorscheme用)
vim.opt.list = false

-- auto-session設定
vim.o.sessionoptions="blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

-- Leader Key
vim.g.mapleader = " "

-- Razor/Blazor ファイルタイプ
vim.filetype.add({
	extension = {
		razor = "razor",
		cshtml = "razor",
	},
})

-- キーマップのタイムアウト設定
vim.opt.timeout = true
vim.opt.timeoutlen = 300  -- リーダーキーのタイムアウト（ミリ秒）
vim.opt.ttimeoutlen = 10  -- キーコードのタイムアウト

local keymap = vim.keymap

-- キーバインド
-- 画面分割
keymap.set("n", "ss", ":split<Return><C-w>w")
keymap.set("n", "sv", ":vsplit<Return><C-w>w")
-- アクティブウィンドウの移動
--keymap.set('', 'sh', '<C-w>h')
--keymap.set('', 'sk', '<C-w>k')
--keymap.set('', 'sj', '<C-w>j')
--keymap.set('', 'sl', '<C-w>l')

-- Emacs like keybinding
keymap.set("i", "<C-f>", "<Right>")

-- jjでEscする
keymap.set("i", "jj", "<Esc>")

-- 設定ファイルを開く
keymap.set("n", "<F1>", ":edit $MYVIMRC<CR>")

-- Autocmd設定
local autocmd = require("utils.autocmd")
autocmd.common.setup_diagnostic_float()

