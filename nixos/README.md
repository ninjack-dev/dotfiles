## To-Do
- [ ] Fully modularize Nix configuration
- [ ] Replace hardcoded instances of username with proper Nix variable
- [ ] Organize `environment.systemPackages`
    - I'd like to write a tiny wrapper of some kind which can provide a sort of "rationale" string attribute to a package, ideally with a minimal interface to make it easy to set. 
        - The simplest solution would be to just rip a comment next to a given package name.
- [ ] Break out configuration for separate hosts
- [ ] Fix dolphin
    - [ ] Add proper Qt theme
        - Look into making the Qt theme identical to the GTK theme. If this is not possible, consider moving on to a Gtk-based file manager.
    - [ ] Integrate proper terminal (not Konsole)
    - [ ] Fix scaling issue for panels
- [ ] Set up new Nix LS
- [ ] Write Godot package
    - Pulls binaries/desktop file/icon and wraps them instead of building from source. Allows trivial version selection, or for multiple version installation with an override.
### Config-Specific
- PAM
    - [ ] Potentially add [pam-any](https://github.com/ChocolateLoverRaj/pam-any)
        - I'm still unsure of the security implications of this. I've read that it's difficult for something like this to exist due to... async stuff, for lack of a better description. Regardless, this is an ideal solution to having both a password field and a fingerprint reader setup.
### Tenative
- [ ] Implement [Home Manager](https://github.com/nix-community/home-manager) support
    - The concern here is separation of the platform-agnostic configurations into usable formats. More research is required.
    - [ ] Add Stylix
