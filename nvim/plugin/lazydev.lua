vim.pack.add({
  { src = "https://github.com/folke/lazydev.nvim", version = vim.version.range("1.x") }
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "lua",
  callback = function()
    require("lazydev").setup({
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "lspconfig",          words = { "lspconfig.settings" } },
      },
    })
  end,
})
