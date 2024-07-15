-- local status,lualine = pcall(require, "lualine")
-- if (not status) then return end
-- 
-- require('lualine').setup {
--   options = {
--     theme = 'rose-pine',
--   --   -- theme ='solarized_dark'
--   },
-- }




local status, lualine = pcall(require, "lualine")
if not status then return end

local function xcodebuild_device()
  if vim.g.xcodebuild_platform == "macOS" then
    return " macOS"
  end

  if vim.g.xcodebuild_os then
    return " " .. vim.g.xcodebuild_device_name .. " (" .. vim.g.xcodebuild_os .. ")"
  end

  return " " .. vim.g.xcodebuild_device_name
end

lualine.setup({
  options = {
    globalstatus = true,
    theme = "onedark",
    icons_enabled = true,
    symbols = {
      alternate_file = "#",
      directory = "",
      readonly = "",
      unnamed = "[No Name]",
      newfile = "[New]",
    },
    disabled_buftypes = { "quickfix", "prompt" },
    component_separators = { left = '', right = ''},
    section_separators = { left = '', right = ''},
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { 'branch', 'diff', 'diagnostics' },
    lualine_c = { "encoding", "fileformat", "filetype", "filename"},
    lualine_x = {
      { "' ' .. vim.g.xcodebuild_last_status", color = { fg = "#a6e3a1" } },
      -- { "'󰙨 ' .. vim.g.xcodebuild_test_plan", color = { fg = "#a6e3a1", bg = "#161622" } },
      { xcodebuild_device, color = { fg = "#f9e2af", bg = "#161622" } },
    },
    lualine_y = {
      { "progress" },
    },
    lualine_z = {
      { "location" },
    },
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = { "filename" },
    lualine_x = { "location" },
    lualine_y = {},
    lualine_z = {},
  },
  extensions = { "nvim-dap-ui", "quickfix", "trouble", "nvim-tree", "lazy", "mason" },
})
