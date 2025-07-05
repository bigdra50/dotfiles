local M = {}

-- プラグインを安全に読み込む
function M.safe_require(module_name)
  local status, module = pcall(require, module_name)
  if not status then
    if vim.g.debug_plugin_loading then
      vim.notify("Failed to load " .. module_name .. ": " .. tostring(module), vim.log.levels.WARN)
    end
    return nil
  end
  return module
end

-- 複数のプラグインを安全に読み込む
function M.safe_require_multiple(...)
  local modules = {}
  for _, module_name in ipairs({...}) do
    local module = M.safe_require(module_name)
    if not module then
      return nil
    end
    table.insert(modules, module)
  end
  return unpack(modules)
end

-- プラグインのセットアップを安全に実行
function M.safe_setup(module_name, config)
  local module = M.safe_require(module_name)
  if module and module.setup then
    local status, err = pcall(module.setup, config or {})
    if not status then
      vim.notify("Failed to setup " .. module_name .. ": " .. tostring(err), vim.log.levels.ERROR)
      return false
    end
    return true
  end
  return false
end

-- 条件付きでプラグインを読み込む
function M.when(condition, module_name, callback)
  if condition then
    local module = M.safe_require(module_name)
    if module and callback then
      callback(module)
    end
    return module
  end
  return nil
end

return M