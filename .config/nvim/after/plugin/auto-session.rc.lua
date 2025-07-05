local status, auto_session = pcall(require, "auto-session")
if not status then
  return
end

local path_utils = require('utils.path')

auto_session.setup({
  log_level = "error",
  auto_session_suppress_dirs = {
    path_utils.home(),
    path_utils.join(path_utils.home(), "Projects"),
    path_utils.join(path_utils.home(), "Downloads"),
    "/"
  },
})