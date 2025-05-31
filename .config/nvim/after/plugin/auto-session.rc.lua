local auto_session = require("auto-session")

-- auto-session の設定
auto_session.setup({
  auto_restore_enabled = true,
  auto_session_suppress_dirs = { "~/Downloads", "~/Documents", "~/Desktop" },
  auto_save_enabled = true,
})
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
