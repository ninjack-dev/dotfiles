local opt = vim.opt
local o = vim.o
local g = vim.g

-- UI
-- TODO: Figure out how to organize/sort this section. UI semantics are interesting.
o.linebreak = true
o.completeopt = "fuzzy"
o.winborder = "rounded"
o.laststatus = 3
o.cursorline = true
o.cursorlineopt = "number"
o.splitkeep = "screen"
o.number, o.relativenumber = true, true
o.signcolumn = "yes"
o.splitbelow, o.splitright = true, true
opt.fillchars = { eob = " " }

o.tabstop, o.softtabstop = 2, 2
o.shiftwidth, o.numberwidth = 2, 2

o.ruler = true

o.title = true
o.showmode = false

o.nrformats = vim.o.nrformats .. ",alpha"
o.clipboard = "unnamedplus"
o.timeoutlen = 400
o.undofile = true
o.updatetime = 250

-- Editing & Navigation
opt.whichwrap:append("<>[]hl")
o.expandtab = true
o.smartindent = true
o.ignorecase, o.smartcase = true, true

o.mouse = "a" -- Don't @ me
vim.cmd([[
  aunmenu PopUp.How-to\ disable\ mouse
  aunmenu PopUp.-1-
]])

opt.shortmess:append("sI")

-- Config Provisioning
o.exrc = true
o.secure = true

g.loaded_node_provider = 0
g.loaded_python3_provider = 0
g.loaded_perl_provider = 0
g.loaded_ruby_provider = 0
