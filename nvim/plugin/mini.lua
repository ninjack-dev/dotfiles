vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.nvim" },
})

-- Text editing
require("mini.comment").setup()
require("mini.pairs").setup()
require("mini.surround").setup()

-- Workflow
require("mini.files").setup()
require("mini.git").setup()

do
  require("mini.pick").setup()

  MiniPick.registry.filetypes = function()
    local fts = vim.fn.getcompletion("", "filetype")
    local source = { items = fts, name = "Filetypes", choose = function() end }
    local ft = MiniPick.start({ source = source })
    if ft ~= nil then
      vim.bo.filetype = ft
    end
  end

  MiniPick.registry.pickers = function()
    local pickers = MiniPick.registry
    pickers.resume = nil
    local items = vim.tbl_keys(pickers)
    table.sort(items)
    local source = { items = items, name = "Pickers", choose = function() end }
    local picker = MiniPick.start({ source = source })
    if picker ~= nil then
      return MiniPick.registry[picker]()
    end
  end
end

-- GUI
require("mini.icons").setup()
require("mini.tabline").setup({
  format = function(buf_id, label)
    -- I tried making an autocommand for misc. buffer events, but the list would fail to update in certain scenarios
    require("utils.buffer_list").update_list()
    local suffix = (vim.bo[buf_id].modified and "*" or "") .. " "
    local buffer_index = require("utils.buffer_list").by_bufnr(buf_id)
    return " " .. tostring(buffer_index) .. MiniTabline.default_format(buf_id, label):gsub(" $", "") .. suffix
  end,
})
require("mini.statusline").setup()
