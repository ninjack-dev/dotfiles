-- TODO: Either:
-- - Make this a template which can be created with something like `:Nvimrc`
-- or
-- - Add it as a default feature to my general config
-- - Add support for Vimscript files
-- - MAYBE add support for Python?

vim.cmd [[set runtimepath+=.nvim]]

---@param path string
local function recurse_dofile(path)
  for name, type in vim.fs.dir(path) do
    if type == "file" and name:sub(-4) == ".lua" then
      local ok, err = pcall(function() assert(loadstring(vim.secure.read(path .. name) --[[@as string]], name))() end)
      if not ok then
        vim.notify("Secure load failed or denied for " .. name .. ": " .. err, vim.log.levels.WARN)
      end
    elseif type == "directory" or type == "link" and name ~= "lsp" then -- Skip lsp info; see `:help exrc`
      recurse_dofile(path .. name)
    end
  end
end

recurse_dofile(".nvim/")

vim.filetype.add({
  filename = {
    ['nvin'] = 'lua',
  },
})
