# Ninjackson's Dotfiles

> [!CAUTION]
> This repository is **unstable** at best. Breaking changes happen consistently, and there is a general lack of understanding on the author's part regarding several elements, specifically NixOS. 

## Installation
```bash
git clone https://github.com/NinjacksonXV/dotfiles.git $USER/.config
```
## To-Do List
- [ ] Provide link directory to all relevant READMEs
- [ ] Remove Nushell's auto-generated modules (Oh My Posh, Zoxide) from the tree; they are falsely inflated in the language panel on GitHub
- [ ] Transition over to GNU Stow management
    - Track the files in the following directories
        - `~/.bashrc`
	    - `~/.local/bin`
	    - `~/.local/share/applications`
	    - `~/.local/share/qalculate/definitions/functions.xml`
            - For this particular file, write a small hook which can assemble multiple function definition files into this monolith using `yq`, `nu`, or `pwsh`
### NixOS
> [!WARNING]
> This installation "guide" does NOT cover the usecase of installing to a fresh operating system. The underlying assumption (currently) is that 1. NixOS is installed on the host, and 2. that the host is a Framework 13 Intel 13th gen. It is *not* designed for multiple hosts (yet). This is on the [to-do list](./nixos/README.md#to-do).

The `./nixos` folder is meant to be symlinked to from `/etc/nixos`, at which point using the stock `sudo nixos-rebuild switch` will work as intended, pulling from `flake.nix` automatically.
