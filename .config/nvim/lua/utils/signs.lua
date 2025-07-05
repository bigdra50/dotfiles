local M = {}

-- デフォルトのアイコンセット
M.icons = {
  diagnostics = {
    Error = " ",
    Warn = " ",
    Hint = "󰠠 ",
    Info = " ",
  },
  dap = {
    Breakpoint = "",
    BreakpointCondition = "",
    BreakpointRejected = "",
    Stopped = "",
    LogPoint = "",
  },
  git = {
    added = "",
    modified = "",
    removed = "",
  },
  kinds = {
    Text = "",
    Method = "󰆧",
    Function = "󰊕",
    Constructor = "",
    Field = "󰇽",
    Variable = "󰂡",
    Class = "󰠱",
    Interface = "",
    Module = "",
    Property = "󰜢",
    Unit = "",
    Value = "󰎠",
    Enum = "",
    Keyword = "󰌋",
    Snippet = "",
    Color = "󰏘",
    File = "󰈙",
    Reference = "",
    Folder = "󰉋",
    EnumMember = "",
    Constant = "󰏿",
    Struct = "",
    Event = "",
    Operator = "󰆕",
    TypeParameter = "󰅲",
  },
}

-- サインを定義
function M.define(name, opts)
  vim.fn.sign_define(name, opts)
end

-- 複数のサインを一括定義
function M.define_signs(signs)
  for name, opts in pairs(signs) do
    M.define(name, opts)
  end
end

-- 診断サインをセットアップ
function M.setup_diagnostics(custom_icons)
  local icons = vim.tbl_extend("force", M.icons.diagnostics, custom_icons or {})
  
  local signs = {}
  for type, icon in pairs(icons) do
    local hl = "DiagnosticSign" .. type
    signs[hl] = { text = icon, texthl = hl, numhl = "" }
  end
  
  M.define_signs(signs)
  
  -- 診断の設定も同時に行う
  vim.diagnostic.config({
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    virtual_text = {
      spacing = 2,
      prefix = "●",
    },
    float = {
      source = "always",
      border = "rounded",
    },
  })
end

-- DAPのサインをセットアップ
function M.setup_dap(custom_icons)
  local icons = vim.tbl_extend("force", M.icons.dap, custom_icons or {})
  
  local signs = {
    DapBreakpoint = { 
      text = icons.Breakpoint, 
      texthl = "DiagnosticError", 
      linehl = "", 
      numhl = "" 
    },
    DapBreakpointCondition = { 
      text = icons.BreakpointCondition, 
      texthl = "DiagnosticError", 
      linehl = "", 
      numhl = "" 
    },
    DapBreakpointRejected = { 
      text = icons.BreakpointRejected, 
      texthl = "DiagnosticError", 
      linehl = "", 
      numhl = "" 
    },
    DapStopped = { 
      text = icons.Stopped, 
      texthl = "DiagnosticOk", 
      linehl = "DapStoppedLine", 
      numhl = "" 
    },
    DapLogPoint = { 
      text = icons.LogPoint, 
      texthl = "DiagnosticInfo", 
      linehl = "", 
      numhl = "" 
    },
  }
  
  M.define_signs(signs)
end

-- アイコンを取得
function M.get_icon(category, name)
  local category_icons = M.icons[category]
  if category_icons then
    return category_icons[name] or ""
  end
  return ""
end

-- カスタムアイコンセットを登録
function M.register_icons(category, icons)
  M.icons[category] = vim.tbl_extend("force", M.icons[category] or {}, icons)
end

return M