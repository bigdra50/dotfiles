-- Plugins module entry point
return {
  { import = "plugins.ui" },
  { import = "plugins.lsp" },
  { import = "plugins.editor" },
  { import = "plugins.ai" },
  { import = "plugins.go" },
}