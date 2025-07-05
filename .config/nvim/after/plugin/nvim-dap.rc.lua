local keymap = require('utils.keymap')

local function setupListeners()
  local dap = require("dap")
  
  -- DAPの基本キーマップを直接設定
  vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Continue" })
  vim.keymap.set("n", "<leader>dC", dap.run_to_cursor, { desc = "Run To Cursor" })
  vim.keymap.set("n", "<leader>ds", dap.step_over, { desc = "Step Over" })
  vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Step Into" })
  vim.keymap.set("n", "<leader>do", dap.step_out, { desc = "Step Out" })
  vim.keymap.set({ "n", "v" }, "<Leader>dh", require("dap.ui.widgets").hover, { desc = "Hover" })
  vim.keymap.set({ "n", "v" }, "<Leader>de", function()
    local dapui_ok, dapui = pcall(require, "dapui")
    if dapui_ok then
      dapui.eval()
    end
  end, { desc = "Eval" })
end

local plugin = require('utils.plugin')
local path_utils = require('utils.path')

local dap = plugin.safe_require('dap')
if not dap then return end

local xcodebuild = plugin.safe_require('xcodebuild.integrations.dap')
if not xcodebuild then return end

-- Use path utility to find codelldb
local codelldbPath = path_utils.get_tool_path("codelldb")

if codelldbPath ~= "" and codelldbPath ~= nil then
  xcodebuild.setup(codelldbPath)
  -- CodeLLDB設定完了（メッセージを非表示）
else
  vim.notify("CodeLLDB not found. Please install VS Code LLDB extension.", vim.log.levels.WARN)
end

-- DAPサインの設定
local signs = require('utils.signs')
signs.setup_dap()

setupListeners()

--stylua: ignore start
vim.keymap.set("n", "<leader>dd", xcodebuild.build_and_debug, { desc = "Build & Debug" })
vim.keymap.set("n", "<leader>dr", xcodebuild.debug_without_build, { desc = "Debug Without Building" })
vim.keymap.set("n", "<leader>dt", xcodebuild.debug_tests, { desc = "Debug Tests" })
vim.keymap.set("n", "<leader>dT", xcodebuild.debug_class_tests, { desc = "Debug Class Tests" })
vim.keymap.set("n", "<leader>b", xcodebuild.toggle_breakpoint, { desc = "Toggle Breakpoint" })
vim.keymap.set("n", "<leader>B", xcodebuild.toggle_message_breakpoint, { desc = "Toggle Message Breakpoint" })
--stylua: ignore end

vim.keymap.set("n", "<leader>dx", function()
  xcodebuild.terminate_session()
  require("dap").listeners.after["event_terminated"]["me"]()
end, { desc = "Terminate debugger" })