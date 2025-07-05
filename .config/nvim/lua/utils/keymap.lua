local M = {}

-- デフォルトオプション
local default_opts = { noremap = true, silent = true }

-- 単一のキーマップを設定
function M.set(mode, lhs, rhs, opts)
  opts = vim.tbl_extend("force", default_opts, opts or {})
  vim.keymap.set(mode, lhs, rhs, opts)
end

-- ノーマルモードのキーマップ
function M.nmap(lhs, rhs, opts)
  M.set("n", lhs, rhs, opts)
end

-- ビジュアルモードのキーマップ
function M.vmap(lhs, rhs, opts)
  M.set("v", lhs, rhs, opts)
end

-- インサートモードのキーマップ
function M.imap(lhs, rhs, opts)
  M.set("i", lhs, rhs, opts)
end

-- ターミナルモードのキーマップ
function M.tmap(lhs, rhs, opts)
  M.set("t", lhs, rhs, opts)
end

-- 複数モードのキーマップ
function M.map(modes, lhs, rhs, opts)
  if type(modes) == "string" then
    modes = { modes }
  end
  for _, mode in ipairs(modes) do
    M.set(mode, lhs, rhs, opts)
  end
end

-- バルクキーマップ設定
function M.bulk_set(mappings)
  for _, mapping in ipairs(mappings) do
    local mode, lhs, rhs, opts = unpack(mapping)
    M.set(mode, lhs, rhs, opts)
  end
end

-- リーダーキー付きキーマップ
function M.leader(lhs, rhs, opts)
  M.nmap("<leader>" .. lhs, rhs, opts)
end

-- 条件付きキーマップマネージャー
function M.conditional_keymaps(name)
  local keymaps = {}
  local active = false
  
  local manager = {
    name = name,
    
    -- キーマップを追加
    add = function(mode, lhs, rhs, opts)
      table.insert(keymaps, {mode, lhs, rhs, opts})
      if active then
        M.set(mode, lhs, rhs, opts)
      end
      return manager
    end,
    
    -- 複数のキーマップを追加
    add_bulk = function(mappings)
      for _, mapping in ipairs(mappings) do
        manager.add(unpack(mapping))
      end
      return manager
    end,
    
    -- キーマップを有効化
    activate = function()
      if not active then
        active = true
        for _, mapping in ipairs(keymaps) do
          M.set(unpack(mapping))
        end
      end
      return manager
    end,
    
    -- キーマップを無効化
    deactivate = function()
      if active then
        active = false
        for _, mapping in ipairs(keymaps) do
          local mode, lhs = mapping[1], mapping[2]
          pcall(vim.keymap.del, mode, lhs)
        end
      end
      return manager
    end,
    
    -- 状態を取得
    is_active = function()
      return active
    end,
    
    -- トグル
    toggle = function()
      if active then
        manager.deactivate()
      else
        manager.activate()
      end
      return manager
    end
  }
  
  return manager
end

-- Which-key形式のキーマップ定義をサポート
function M.which_key_register(mappings, opts)
  opts = opts or {}
  
  local function process_mapping(prefix, mapping_table)
    for key, value in pairs(mapping_table) do
      local full_key = prefix .. key
      
      if type(value) == "table" then
        if value[1] then
          -- コマンドとdescriptionがある場合
          local cmd = value[1]
          local desc = value[2] or value.desc
          M.nmap(full_key, cmd, { desc = desc })
        else
          -- ネストされたマッピング
          process_mapping(full_key, value)
        end
      elseif type(value) == "string" then
        -- コマンドのみ
        M.nmap(full_key, value)
      end
    end
  end
  
  process_mapping("", mappings)
end

return M