-- TODO: Make this a template callbe with something like `:Nvimrc`
vim.cmd[[set runtimepath+=.nvim]]

for name, type in vim.fs.dir(".nvim") do
  if type == "file" and name:sub(-4) == ".lua" then

    local ok, err = pcall(function()
      vim.secure.read(".nvim/" .. name)
    end)

    if not ok then
      vim.notify("Secure load failed or denied for " .. name .. ": " .. err, vim.log.levels.WARN)
    end
  end
end
