local path_utils = require("utils.path")
vim.g.python3_host_prog = path_utils.find_python_venv()

require("base")
require("config.lazy")
