vim.pack.add({
  {
    src = "https://github.com/saghen/blink.cmp",
    name = "blink",
    version = vim.version.range("1.x"),
  },
})

require("blink.cmp").setup({
  keymap = { preset = "default" },
})
