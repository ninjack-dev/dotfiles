# Ninjackson's Dotfiles

> [!CAUTION]
> This repository is **unstable** at best. Breaking changes happen consistently, and there is a general lack of understanding on the author's part regarding several elements, specifically NixOS. 

## Installation
```bash
git clone https://github.com/NinjacksonXV/dotfiles.git $USER/.config
```
### NixOS
> [!WARNING]
> This installation "guide" does NOT cover the usecase of installing to a fresh operating system. The underlying assumption (currently) is that 1. NixOS is installed on the host, and 2. that the host is a Framework 13 Intel 13th gen. It is *not* designed for multiple hosts (yet). This is on the [to-do list](./nixos/README.md#to-do).

The `/nixos` folder is designed to be symlinked to from `/etc/nixos`, at which point using the stock `sudo nixos-rebuild switch` will work as intended, pulling from `flake.nix` automatically. It may be possible to install via `sudo nixos-rebuild switch --flake '.#'` (assuming the command is run from `~/.config/nixos`); I have not tested this yet. 
