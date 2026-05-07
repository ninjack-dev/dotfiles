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

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking text",
  callback = function()
    vim.hl.on_yank()
  end,
})

vim.api.nvim_create_autocmd({ "BufNew", "BufDelete", "BufEnter" }, {
  desc = "Update simple buffer list",
  callback = function()
    require("utils.buffer_list").update_list()
  end,
})

---@param ev vim.api.keyset.create_autocmd.callback_args
---@param cd_func function(string)
local function handle_osc7(ev, cd_func)
  local dir, n = string.gsub(ev.data.sequence, "\027]7;file://[^/]*", "")
  if n > 0 then
    if vim.fn.isdirectory(dir) == 0 then
      vim.notify("invalid dir: " .. dir, vim.log.levels.WARN)
      return
    end
    vim.b[ev.buf].osc7_dir = dir
    cd_func(dir)
  end
end

vim.api.nvim_create_autocmd({ "TermRequest" }, {
  desc = "Handles OSC 7 directory change requests from the floating terminal",
  callback = function(ev)
    if ev.buf ~= require("utils.floating_terminal").get_floating_terminal_buf() then
      return
    end
    handle_osc7(ev, vim.cmd.cd)
  end,
})

vim.api.nvim_create_autocmd({ "TermRequest" }, {
  desc = "Handles OSC 7 directory change requests for this window",
  callback = function(ev)
    if vim.api.nvim_get_current_buf() == ev.buf then
      return
    end
    handle_osc7(ev, vim.cmd.lcd)
  end,
})
