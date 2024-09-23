## To-Do
- [ ] Break out configuration for separate hosts
- [ ] Fix dolphin
    - [ ] Add proper Qt theme
        - Look into making the Qt theme identical to the GTK theme. If this is not possible, consider moving on to a Gtk-based file manager.
    - [ ] Integrate proper terminal (not Konsole)
    - [ ] Fix scaling issue for panels
### Config-Specific
- [ ] **Framework**: Look more into setting up fingerprint reader
    - Currently, the fingerprint reader works for sudo; this is very nice, but I don't know why it works. I did not set it up as an option for sudo, to my knowledge. Perhaps there is some dbus/PAM shenanigans that I simply do not understand. Regardless, I would also like fingerprint integration for the following services:
        - Hyprlock (Hyprland lockscreen)
        - Authentication frontend
### Tenative
- [ ] Implement [Home Manager](https://github.com/nix-community/home-manager) support
    - The concern here is separation of the platform-agnostic configurations into usable formats. More research is required.
