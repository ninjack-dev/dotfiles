vim.g.neovide_scale_factor = 0.85
local change_scale_factor = function(delta)
  vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * delta
end
vim.keymap.set("n", "<C-=>", function()
  change_scale_factor(1.25)
end)
vim.keymap.set("n", "<C-->", function()
  change_scale_factor(1/1.25)
end)

vim.keymap.set('v', '<C-S-c>', '"+y') -- Copy visual mode
vim.keymap.set('n', '<C-S-v>', '"+P') -- Paste normal mode
vim.keymap.set('v', '<C-S-v>', '"+P') -- Paste visual mode
-- vim.keymap.set('c', '<C-S-v>', '<C-R>+') -- Paste command mode
vim.keymap.set('c', '<C-S-v>', '<C-R>+') -- Paste command mode
vim.keymap.set('i', '<C-S-v>', '<ESC>l"+Pli') -- Paste insert mode

-- Allow clipboard copy-paste in Neovim
vim.api.nvim_set_keymap('', '<C-S-v>', '+p<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('!', '<C-S-v>', '<C-R>+', { noremap = true, silent = true })
vim.api.nvim_set_keymap('t', '<C-S-v>', '<C-R>+', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<C-S-v>', '<C-R>+', { noremap = true, silent = true })
