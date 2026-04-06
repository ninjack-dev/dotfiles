vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.nvim" }
})

-- Text editing
require('mini.comment').setup()
require('mini.pairs').setup()
require('mini.surround').setup()

-- Workflow
require('mini.files').setup()
require('mini.git').setup()

-- GUI
require('mini.icons').setup()
require('mini.tabline').setup()
require('mini.statusline').setup()
