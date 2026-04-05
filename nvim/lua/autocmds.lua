vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "DirChanged" }, {
  desc = 'Set the window title to "<filename> in <directory>"',
  callback = function()
    local filename = vim.fn.expand("%:t")
    local directory = vim.fn.expand("%:p:h")
    vim.o.titlestring = string.format("%s in %s", filename, directory)
  end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  desc = "Create parent directories of file if needed",
  callback = function()
    return vim.fn.mkdir(vim.fn.expand("<afile>:p:h"), "p") == true
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function()
    pcall(vim.treesitter.start)
  end,
})
