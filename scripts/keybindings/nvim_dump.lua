local modes = { "n", "v", "i", "x", "o", "t", "c" }
local dump = {}

for _, mode in ipairs(modes) do
  for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
    table.insert(dump, {
      mode = mode,
      lhs = map.lhs,
      rhs = map.rhs or "",
      desc = map.desc or "",
      callback = map.callback ~= nil,
    })
  end
end

local path = vim.env.KB_DUMP_PATH
if path == nil or path == "" then
  error("KB_DUMP_PATH is not set")
end

local file = io.open(path, "w")
if file == nil then
  error("failed to open KB_DUMP_PATH for writing: " .. path)
end

file:write(vim.json.encode(dump))
file:close()
