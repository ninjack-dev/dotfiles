require("nvchad.configs.lspconfig").defaults()

local servers = { "html", "cssls", "clangd", "ts_ls", "bashls", "gopls", "pyright",
  "arduino_language_server", "csharp_ls", "openscad_lsp", 'nil_ls', 'vala_ls', 'taplo' }

vim.lsp.enable(servers)

vim.lsp.config('nil_ls', {
  settings = {
    ['nil'] = {
      formatting = {
        command = { "nixfmt" },
      },
    },
  },
})

vim.lsp.config('vala_ls', {
  single_file_support = true,
})

vim.lsp.config('taplo', {
  root_markers = { "taplo.toml", ".taplo.toml", ".git" }, -- Waiting for https://github.com/neovim/nvim-lspconfig/pull/3145
})
