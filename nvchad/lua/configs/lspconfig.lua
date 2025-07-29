require("nvchad.configs.lspconfig").defaults()

local servers = {
  arduino_language_server = {},
  awk_ls = {},
  bashls = {},
  clangd = {},
  csharp_ls = {},
  cssls = {},
  gdscript = {},
  gopls = {},
  html = {},
  nixd = {
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
  },
  nushell = {},
  openscad_lsp = {},
  pyright = {},
  tombi = {},
  ts_ls = {},
  vala_ls = {
    single_file_support = true,
  },
  yamlls = {
    settings = {
      yaml = {
        format = { enable = true },
        schemas = {
          ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
          ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = { "*compose*.y*ml" },
        }
      }
    }
  },
}

for name, opts in pairs(servers) do
  vim.lsp.enable(name)
  vim.lsp.config(name, opts)
end
