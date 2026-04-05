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
1) `./lua/` - Dependency-free config, autocommands, etc. Must be `require`d in `init.lua`; should be kept relatively small. If there are plugins in `./plugin/` which have a dependency, they should be `vim.pack.add`ed in this directory. It also contains `utils`.
2) `./plugin/` - All third-party plugins
3) `./after/plugin/` - Dependency-oriented config, e.g. key mappings, language server config, etc.

### Scripts
`./scripts/` contains CLI utilities meant to be usable from a terminal managed by the Neovim session. One example is `nvin`, which accepts file contents from standard input and pipes them into a buffer in the parent Neovim.
