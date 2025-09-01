local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "black" },
    css = { "prettier" },
    html = { "prettier" },
    bash = { "prettier" },
    sh = { "prettier" }
  },

  formatters = {
    prettier = {
      append_args = function()
        return { "--plugin=prettier-plugin-sh" }
      end
    }
  },
}

require("conform").setup(options)
