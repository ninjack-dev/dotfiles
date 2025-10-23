require("nvchad.configs.lspconfig").defaults()

local servers = {
  arduino_language_server = {},
  awk_ls = {},
  bashls = {},
  clangd = {},
  csharp_ls = {},
  cssls = {},
  -- denols = {
  --   root_dir = require("lspconfig").util.root_pattern("deno.json", "deno.jsonc"),
  -- },
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
  kotlin_lsp = {},
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
  powershell_es = { bundle_path = '/nix/store/vwd5fzfm08hln06ni1pyvjhx9fz3s6hw-powershell-editor-services-4.4.0/lib/powershell-editor-services/' }, -- TODO: Replace this hardcoded path with a manually-constructed invocation of the powershell-editor-services wrapper
  pyright = {},
  rust_analyzer = {
    settings = {
      ['rust-analyzer'] = {}
    }
  },
  tombi = {},
  ts_ls = { root_dir = require("lspconfig").util.root_pattern("package.json"), single_file_support = false },
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
  vim.lsp.config(name, opts)
  vim.lsp.enable(name)
end
