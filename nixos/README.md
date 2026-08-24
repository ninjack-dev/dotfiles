# NixOS Config

***Now dendritic free![^1]***

**Layout**: 
- `modules` -- All NixOS config for `nixos-laptop`
- `nixosModules` -- Custom NixOS modules
- `packages` -- Custom packages

The only current host is `nixos-laptop`, thus no `hosts` dir. It's a perpetual WIP and I've yet to find an ideal organizational pattern. Config modules are laid out strictly for organizational purposes and are not yet exposed in the flake (although this is planned for some modules, especially anything dev-related). The rule of thumb is that if a "semantic module" takes more than one attribute set to define, then it should be its own file or directory; otherwise, dump it in `configuration.nix`.

[^1]: This repo has never actually used `flake-parts`. The only feature it provides that I would currently use is the cleaner module references, and I'd rather not pull in an entire dependency and refactor the tree for this minor feature. This might change if/when I compartmentalize a bit more and use some modules externally (e.g. shared K3s config).
