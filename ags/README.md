> [!warning]
> If installing on NixOS, it is necessary to use the package and/or flake provided on the Aylur/ags repository instead of the one hosted on Nixpkgs, as it is missing several "optional" packages. The current iteration of my `flake.nix` contains this setup (albeit rather uncleanly). 

This configuration is one of the examples from the ags repository, with some minor additions. **Very WIP**. The current config will likely not stick around once I've mastered NixOS package overlays/overrides and can pull some more custom dotfiles.

According to the example README:
> types are symlinked to:
> `/nix/store/zks2f1jx6jj4d161gmsm10q48dviixwb-ags-1.8.2/share/com.github.Aylur.ags/types`
I believe this is done during installation.

## To-Do
- [ ] Fix multi-monitor bar support
