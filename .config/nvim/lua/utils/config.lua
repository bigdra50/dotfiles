local M = {}

-- デフォルト設定とユーザー設定をマージ
function M.merge(defaults, user_config)
  return vim.tbl_deep_extend("force", defaults, user_config or {})
end

-- 設定の検証
function M.validate(config, schema)
  -- vim.validateを使用した検証
  local ok, err = pcall(vim.validate, schema)
  if not ok then
    vim.notify("Configuration validation failed: " .. err, vim.log.levels.ERROR)
    return false
  end
  return true
end

-- 条件付き設定
function M.when(condition, config)
  if condition then
    return config
  end
  return {}
end

-- OS別の設定
function M.by_os(configs)
  local os_name = vim.loop.os_uname().sysname:lower()
  
  if os_name:match("darwin") then
    return configs.mac or configs.default or {}
  elseif os_name:match("linux") then
    return configs.linux or configs.default or {}
  elseif os_name:match("windows") then
    return configs.windows or configs.default or {}
  end
  
  return configs.default or {}
end

-- 遅延評価用の設定
function M.lazy(fn)
  return setmetatable({}, {
    __index = function(_, key)
      local result = fn()
      return result[key]
    end,
    __call = function()
      return fn()
    end,
  })
end

-- グローバル変数からの設定読み込み
function M.from_global(var_name, defaults)
  local value = vim.g[var_name]
  if value == nil then
    return defaults
  end
  if type(defaults) == "table" and type(value) == "table" then
    return M.merge(defaults, value)
  end
  return value
end

-- 環境変数からの設定読み込み
function M.from_env(env_name, default, transform)
  local value = os.getenv(env_name)
  if value == nil then
    return default
  end
  if transform then
    return transform(value)
  end
  return value
end

-- 設定のキャッシュ
local config_cache = {}

function M.cached(key, fn)
  if config_cache[key] == nil then
    config_cache[key] = fn()
  end
  return config_cache[key]
end

-- プラグイン設定のビルダー
function M.plugin_setup(defaults)
  return function(user_config)
    local config = M.merge(defaults, user_config)
    
    -- 共通の設定処理
    if config.enabled == false then
      return nil
    end
    
    return config
  end
end

-- 設定のデバッグ用ユーティリティ
function M.dump(config, name)
  if vim.g.debug_config then
    print(string.format("=== %s Configuration ===", name or "Plugin"))
    print(vim.inspect(config))
    print("========================")
  end
  return config
end

return M