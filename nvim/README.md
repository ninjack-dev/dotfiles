# Neovim
Neovim 0.12 config, based on `vim.pack`. Somewhat work-in-progress.

TODO:
- [ ] Wrap with:
    - [ ] AppImage as a CI resource
    - [ ] Nix flake output
        - Ideally, have two variants: base and `minimal`, the latter of which would not include language servers or utilities.

## Structure
### Load Order
To minimize the need for load order management, files are organized like so:
1) `./lua/` - Dependency-free config, autocommands, etc. These must be `require`d in `init.lua`; it should be kept relatively small. If there are plugins in `./plugin/` which have a dependency, they should be `vim.pack.add`ed in this directory instead of `./plugin/`. It also contains `utils/`.
2) `./plugin/` - All third-party plugins and their configuration.
3) `./after/plugin/` - Dependency-reliant config, e.g. key mappings, language server config, etc.

### Scripts
`./scripts/` contains CLI utilities for use in Neovim terminals. One example is `nvin`, which accepts content from standard input (e.g. from commands) and pipes them into a buffer in Neovim.
