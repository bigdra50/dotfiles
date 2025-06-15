local status, mason_conform = pcall(require, "mason-conform")
if not status then
  return
end

mason_conform.setup({
  -- Masonでインストールしないフォーマッターがあれば指定
  ignore_install = {"swift-format"}, -- Mac組み込みのswift-formatを使用するため
})