local M = {}

-- OSの判定
M.is_mac = vim.fn.has("mac") == 1
M.is_linux = vim.fn.has("unix") == 1 and not M.is_mac
M.is_windows = vim.fn.has("win32") == 1

-- ホームディレクトリの取得
function M.home()
  return os.getenv("HOME") or os.getenv("USERPROFILE")
end

-- パスの結合
function M.join(...)
  local separator = M.is_windows and "\\" or "/"
  local parts = {...}
  return table.concat(parts, separator)
end

-- Homebrewのプレフィックスを取得（キャッシュ付き）
local homebrew_prefix_cache = nil
function M.homebrew_prefix()
  if homebrew_prefix_cache then
    return homebrew_prefix_cache
  end
  
  local handle = io.popen("brew --prefix 2>/dev/null")
  if handle then
    local result = handle:read("*a"):gsub("%s+", "")
    handle:close()
    if result ~= "" then
      homebrew_prefix_cache = result
      return result
    end
  end
  
  -- フォールバック（Apple SiliconとIntel Macの両方に対応）
  if vim.fn.isdirectory("/opt/homebrew") == 1 then
    homebrew_prefix_cache = "/opt/homebrew"
  else
    homebrew_prefix_cache = "/usr/local"
  end
  
  return homebrew_prefix_cache
end

-- Xcodeのパスを取得（キャッシュ付き）
local xcode_path_cache = nil
function M.xcode_path()
  if xcode_path_cache then
    return xcode_path_cache
  end
  
  local handle = io.popen("xcode-select -p 2>/dev/null")
  if handle then
    local result = handle:read("*a"):gsub("%s+", "")
    handle:close()
    if result ~= "" then
      -- /Contents/Developer を除去してアプリケーションパスを取得
      xcode_path_cache = result:gsub("/Contents/Developer$", "")
      return xcode_path_cache
    end
  end
  
  return nil
end

-- 実行可能ファイルを検索（複数の候補から最初に見つかったものを返す）
function M.find_executable(...)
  local candidates = {...}
  
  for _, candidate in ipairs(candidates) do
    if type(candidate) == "string" then
      local path = vim.fn.exepath(candidate)
      if path ~= "" then
        return path
      end
    elseif type(candidate) == "table" then
      -- テーブルの場合は再帰的に検索
      local result = M.find_executable(unpack(candidate))
      if result then
        return result
      end
    end
  end
  
  return nil
end

-- 特定のディレクトリから実行可能ファイルを検索
function M.find_in_dir(dir, executable)
  local path = M.join(dir, executable)
  if vim.fn.executable(path) == 1 then
    return path
  end
  return nil
end

-- VS Code拡張機能のパスを取得
function M.vscode_extensions()
  return M.join(M.home(), ".vscode", "extensions")
end

-- VS Code拡張機能から特定の実行ファイルを検索
function M.find_vscode_extension_executable(pattern, executable)
  local extensions_dir = M.vscode_extensions()
  if vim.fn.isdirectory(extensions_dir) == 0 then
    return nil
  end
  
  local dirs = vim.fn.glob(M.join(extensions_dir, pattern), false, true)
  for _, dir in ipairs(dirs) do
    local exe_path = M.find_in_dir(dir, executable)
    if exe_path then
      return exe_path
    end
  end
  
  return nil
end

-- Python仮想環境のパスを検索
function M.find_python_venv()
  local venv_paths = {
    M.join(M.home(), ".venvs", "nvim", "bin", "python"),
    M.join(M.home(), ".local", "share", "nvim", "venv", "bin", "python"),
    M.join(vim.fn.stdpath("data"), "venv", "bin", "python"),
  }
  
  for _, path in ipairs(venv_paths) do
    if vim.fn.filereadable(path) == 1 then
      return path
    end
  end
  
  -- uvプロジェクトのPythonを試す
  local uv_python = vim.trim(vim.fn.system('uv run --quiet which python 2>/dev/null'))
  if vim.v.shell_error == 0 and vim.fn.filereadable(uv_python) == 1 then
    return uv_python
  end
  
  -- システムPythonにフォールバック
  return M.find_executable("python3", "python")
end

-- プラットフォーム別のツールパスを取得
function M.get_tool_path(tool_name)
  local tools = {
    ["swift-format"] = function()
      return M.find_executable(
        "swift-format",
        M.join(M.homebrew_prefix(), "bin", "swift-format"),
        "/usr/bin/swift-format"
      )
    end,
    
    ["codelldb"] = function()
      return M.find_executable(
        "codelldb",
        M.join(M.homebrew_prefix(), "bin", "codelldb"),
        "/usr/local/bin/codelldb",
        M.join(M.home(), "tools", "codelldb-aarch64-darwin", "extension", "adapter", "codelldb")
      ) or M.find_vscode_extension_executable("vadimcn.vscode-lldb*", "adapter/codelldb")
    end,
  }
  
  local getter = tools[tool_name]
  if getter then
    return getter()
  end
  
  -- デフォルトの検索
  return M.find_executable(tool_name)
end

return M