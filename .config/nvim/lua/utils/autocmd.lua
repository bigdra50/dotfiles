local M = {}

-- オートコマンドグループを作成
function M.create_augroup(name, clear)
  clear = clear == nil and true or clear
  return vim.api.nvim_create_augroup(name, { clear = clear })
end

-- 単一のオートコマンドを作成
function M.create_autocmd(event, opts)
  return vim.api.nvim_create_autocmd(event, opts)
end

-- 複数のオートコマンドを一括作成
function M.create_autocmds(augroup_name, autocmds)
  local group = M.create_augroup(augroup_name)
  
  for _, autocmd in ipairs(autocmds) do
    local event = autocmd[1]
    local opts = vim.tbl_extend("force", { group = group }, autocmd[2])
    M.create_autocmd(event, opts)
  end
  
  return group
end

-- ファイルタイプ別のオートコマンド
function M.on_filetype(filetype, callback, opts)
  opts = opts or {}
  opts.pattern = filetype
  opts.callback = callback
  
  return M.create_autocmd("FileType", opts)
end

-- バッファ別のオートコマンド
function M.on_buf_enter(pattern, callback, opts)
  opts = opts or {}
  opts.pattern = pattern
  opts.callback = callback
  
  return M.create_autocmd("BufEnter", opts)
end

-- LSPアタッチ時のオートコマンド
function M.on_lsp_attach(callback)
  return M.create_autocmd("LspAttach", {
    callback = function(args)
      local bufnr = args.buf
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      callback(client, bufnr)
    end,
  })
end

-- 遅延実行用のオートコマンド
function M.defer(callback, events)
  events = events or { "BufReadPost", "BufNewFile" }
  
  local function wrapped_callback()
    vim.defer_fn(callback, 0)
  end
  
  return M.create_autocmd(events, {
    once = true,
    callback = wrapped_callback,
  })
end

-- パフォーマンス最適化用：大きなファイルの検出
function M.setup_large_file_detection(size_limit, callback)
  size_limit = size_limit or 1024 * 1024 -- 1MB
  
  return M.create_autocmd("BufReadPre", {
    callback = function(args)
      local file = args.file
      local ok, stats = pcall(vim.loop.fs_stat, file)
      
      if ok and stats and stats.size > size_limit then
        callback(args.buf, stats.size)
      end
    end,
  })
end

-- 共通のオートコマンドパターン
M.common = {
  -- 最後のカーソル位置を復元
  restore_cursor = function()
    M.create_autocmd("BufReadPost", {
      callback = function()
        local mark = vim.api.nvim_buf_get_mark(0, '"')
        local lcount = vim.api.nvim_buf_line_count(0)
        if mark[1] > 0 and mark[1] <= lcount then
          pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
      end,
    })
  end,
  
  -- 行末の空白を強調表示
  highlight_trailing_whitespace = function()
    M.create_autocmd({ "BufNewFile", "BufRead" }, {
      callback = function()
        vim.cmd([[match ErrorMsg '\s\+$']])
      end,
    })
  end,
  
  -- ターミナルモードの設定
  setup_terminal = function()
    M.create_autocmds("TerminalSettings", {
      { "TermOpen", {
        callback = function()
          vim.opt_local.number = false
          vim.opt_local.relativenumber = false
          vim.opt_local.signcolumn = "no"
          vim.cmd("startinsert")
        end,
      }},
    })
  end,
}

return M