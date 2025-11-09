# Ninjackson's Dotfiles
These are my dotfiles. There are many like them, but these ones are mine.

## Deployment
To deploy the NixOS configuration on the only available host (Lenovo Thinkpad E14 Gen 6):
1. Build the system (ensure the `--impure` flag is present[^1])
```sh
sudo nixos-rebuild switch --impure --flake ~/.config/nixos
```
2. Symlink `$HOME/.local/bin` to `$XDG_CONFIG_HOME/bin` to make global scripts available in the `PATH`[^2].
3. For future invocations, symlink `/etc/nixos` to `$XDG_CONFIG_HOME/nixos` and run `rebuild`, which updates flake inputs, rebuilds the system, and offers a reboot interface if the kernel version changed (pass the `full` flag to update the `unstable` nixpkgs flake input).

[^1]: The NixOS configuration uses `callFlake` to pull in my AGS flake, which requires a lock attribute for a pure evaluation; I am forgoing this requirement in favor of easier maintenance.
[^2]: I have not wrapped any of the scripts into Nix derivations, mostly for "portability" and to expedite availability of new scripts. However, this is on an internal todo-list as a low-priority item.
