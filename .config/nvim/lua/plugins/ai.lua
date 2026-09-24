return {
  -- Claude Code IDE 統合 (VS Code 拡張と同じ WebSocket/MCP プロトコルの Neovim 実装)
  {
    "coder/claudecode.nvim",
    -- keys 起動の遅延ロードにすると WebSocket サーバーと lock file が作られず、
    -- 外部ターミナルの claude から発見されないため、起動時にロードする
    event = "VeryLazy",
    opts = {
      -- Claude CLI は WezTerm の別ペインで起動する運用のため、内蔵ターミナル管理は使わない
      -- (プラグインが ~/.claude/ide/<port>.lock を書き、外部の claude が自動接続してくる)
      terminal = { provider = "none" },
      -- diff を現在タブで開くと既存のウィンドウレイアウトが崩れるため新規タブに隔離する
      diff_opts = { open_in_new_tab = true },
    },
    keys = {
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection to Claude" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer to Claude" },
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept Claude diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny Claude diff" },
      { "<leader>ai", "<cmd>ClaudeCodeStatus<cr>", desc = "Claude connection status" },
    },
  },
}
