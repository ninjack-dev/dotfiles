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
