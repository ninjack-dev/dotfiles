local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "black" },
    css = { "prettier" },
    html = { "prettier" },
    bash = { "prettier" },
    sh = { "prettier" },
    gdscript = { "gdscript_formatter" },
  },

  formatters = {
    prettier = {
      append_args = function()
        return { "--plugin=" .. vim.fn.expand("~/.npm-global/lib/node_modules/prettier-plugin-sh/lib/index.js") }
      end
    },
    gdscript_formatter = {
      command = "gdscript-formatter",
      args = { "--stdout" },
    }
  },
}

require("conform").setup(options)
