local status, trouble = pcall(require, "trouble")
if (not status) then return end

trouble.setup({
  auto_open = false,
  auto_close = false,
  auto_preview = true,
  auto_jump = {},
  mode = "quickfix",
  severity = vim.diagnostic.severity.ERROR,
  cycle_results = false,
})

-- キーマッピングの設定
vim.keymap.set("n", "<leader>tt", "<cmd>Trouble quickfix toggle<cr>", { desc = "Open a quickfix" })

-- Xcodebuildイベントに対するautocmdの設定
vim.api.nvim_create_autocmd("User", {
  pattern = { "XcodebuildBuildFinished", "XcodebuildTestsFinished" },
  callback = function(event)
    if event.data.cancelled then
      return
    end

    if event.data.success then
      trouble.close()
    elseif not event.data.failedCount or event.data.failedCount > 0 then
      if next(vim.fn.getqflist()) then
        trouble.open({ focus = false })
      else
        trouble.close()
      end

      trouble.refresh()
    end
  end,
})