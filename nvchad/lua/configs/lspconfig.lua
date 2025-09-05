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
  jsonls = {
    capabilites = (function()
      local capabilites = vim.lsp.protocol.make_client_capabilities()
      capabilites.textDocument.completion.completionItem.snippetSupport = true
      return capabilites
    end)(),
    settings = {
      json = {
        format = { enable = true },
        validate = { enable = true },
        schemas = {
          {
            description = "TypeScript compiler configuration file",
            fileMatch = { "tsconfig*.json" },
            name = "tsconfig.json",
            url = "https://www.schemastore.org/tsconfig.json"
          },
        }
      }
    }
  },
  kotlin_ls = {},
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
  perlnavigator = {},
  pyright = {},
  rust_analyzer = {
    settings = {
      ['rust-analyzer'] = {}
    }
  },
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
