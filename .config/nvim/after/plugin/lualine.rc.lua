local status, lualine = pcall(require, "lualine")
if not status then
  return
end

-- xcodebuild.nvim 統合（グローバル変数を使用）
local xcodebuild_device = function()
  local platform = vim.g.xcodebuild_platform or ""
  local device = vim.g.xcodebuild_device_name or ""
  if device == "" then return "" end

  local icons = {
    iOS = "",
    iPadOS = "",
    macOS = "",
    watchOS = "",
    tvOS = "󰟴",
    visionOS = "󰿄",
  }
  local icon = icons[platform] or ""
  return icon .. " " .. device
end

lualine.setup({
  options = {
    theme = 'auto',
    component_separators = { left = '', right = ''},
    section_separators = { left = '', right = ''},
  },
  sections = {
    lualine_x = {
      { xcodebuild_device, cond = function() return vim.bo.filetype == "swift" end },
      "encoding",
      "fileformat",
      "filetype",
    },
  },
})