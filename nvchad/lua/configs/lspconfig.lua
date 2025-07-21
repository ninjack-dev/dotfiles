require("nvchad.configs.lspconfig").defaults()

local servers = {
  "arduino_language_server",
  "bashls",
  "clangd",
  "csharp_ls",
  "cssls",
  "gdscript",
  "gopls", "pyright",
  "html",
  "nixd",
  "nushell",
  "openscad_lsp",
  "tombi",
  "ts_ls",
  "vala_ls",
  "yamlls",
}

vim.lsp.config("nixd", {
  settings = {
    nixd = {
      nixpkgs = {
        expr = "import <nixpkgs> { }"
      },
      formatting = {
        command = { "nixfmt" }
      },
      options = {
        nixos = {
          expr = '(builtins.getFlake "./.").nixosConfigurations."nixos-laptop".options'
        }
      }
    }
  }
})

vim.lsp.config("yamlls", {
  settings = {
    yaml = {
      format = { enable = true },
      schemas = {
        ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
        ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = { "*compose*.y*ml" },
      }
    }
  }
})

vim.lsp.config("vala_ls", {
  single_file_support = true,
})

vim.lsp.enable(servers)
