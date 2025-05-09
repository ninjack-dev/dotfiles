## To-Do
- [ ] Debug [Godot package](./modules/godot/godot-mono.nix)
    - [The Godot package has now been updated to not use Dotnet 6](https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/development/tools/godot/common.nix). Regardless, the speed at which this package was updated was somewhat agonizing, so going with the prebuilt binary seems nice. There are still bugs to fix, though.
    - Pulls binaries/desktop file/icon and wraps them instead of building from source. Allows trivial version selection, or for multiple version installation with an override. 
    - Currently, the application runs and works as expected. However, I cannot access the Godot C# SDK with my language server. The language server is wrapped, so its `DOTNET_ROOT` variable changes, but this is likely not the reason. I must research how the language server is able to find the SDK on Windows where the location can change; is it in the `.godot` folder, somewhere?
- [ ] Fully modularize Nix configuration
- [ ] Replace hardcoded instances of username with proper Nix variable
- [ ] Organize `environment.systemPackages`
- [ ] Break out configuration for separate hosts
- [ ] Fix dolphin
    - [ ] Add proper Qt theme
        - Look into making the Qt theme identical to the GTK theme. If this is not possible, consider moving on to a Gtk-based file manager.
    - [ ] Integrate proper terminal (not Konsole)
- [ ] Set up new Nix LS
### Config-Specific
- PAM
    - [ ] Potentially add [pam-any](https://github.com/ChocolateLoverRaj/pam-any)
        - I'm still unsure of the security implications of this. I've read that it's difficult for something like this to exist due to... async stuff, for lack of a better description. Regardless, this is an ideal solution to having both a password field and a fingerprint reader setup.
        - Will likely need to package it myself
### Tenative
- [ ] Implement [Home Manager](https://github.com/nix-community/home-manager) support
    - The concern here is separation of the platform-agnostic configurations into usable formats. More research is required.
    - [ ] Add Stylix
