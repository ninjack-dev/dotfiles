{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:
# TODO: Split up as necessary (horrible mess)
{

  imports = lib.filter (
    n:
    let
      s = toString n;
    in
    lib.strings.hasSuffix ".nix" s && !lib.strings.hasSuffix "/configuration.nix" s
  ) (lib.filesystem.listFilesRecursive ./.);

  programs.gnupg.agent.enable = true;

  zramSwap.enable = true;

  services.logind.settings.Login.HandleLidSwitch = "suspend";
  services.logind.settings.Login.HandleLidSwitchDocked = "suspend";

  services.chrony.enable = true;

  services.envfs.enable = true;

  services.resolved = {
    enable = true;
    settings.Resolve = {
      UnicastSingleLabel = "yes";
    };
  };

  # The nixos-hardware module apparently enables TLP.
  # TODO: Determine if replacing TLP with auto-cpufreq is ideal.
  # services.auto-cpufreq.enable = true;

  hardware.i2c.enable = true;
  hardware.keyboard.qmk.enable = true;

  boot.supportedFilesystems = [ "ntfs" ];

  time.timeZone = "America/Los_Angeles";

  # We skip the binfmt provider because it does not
  # clean up unused appimages, defeating the whole point.
  programs.appimage.enable = true;

  services.udisks2.enable = true;

  programs.fish.enable = true;

  systemd.services.fprintd = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "simple";
  };

  services.fprintd = {
    enable = true;
  };

  services.upower.enable = true;

  system.userActivationScripts = {
    setNpmBinDirectory.text = ''
      ${pkgs.nodejs}/bin/npm set prefix $HOME/.npm-global 
    '';

    # TODO:
    # - Replace with update-dev-environments
    # - Realign Hyprland version with the one used in graphics.nix
    updateHyprlandLuarc.text = ''
      LUARC_PATH="$XDG_CONFIG_HOME/hypr/.luarc.json"
      STUB_PATH="${pkgs.unstable.hyprland}/share/hypr/stubs"
      [[ ! -s "$LUARC_PATH" ]] && printf '{}' > "$LUARC_PATH"
      cat <<< "$(${pkgs.jq}/bin/jq --arg new "$STUB_PATH" '
        .workspace.library |= (. // [] | if any(endswith("/share/hypr/stubs"))
            then map(if endswith("/share/hypr/stubs") then $new else . end)
            else [$new] + .
            end)
      ' "$LUARC_PATH")" > "$LUARC_PATH"
    '';
  };

  users.users.jacksonb = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "audio"
      "networkmanager"
      "sudo"
      "docker"
      "podman"
      "dialout"
    ];
    shell = pkgs.zsh;
  };

  nixpkgs.config.allowUnfree = true;

  services.syncthing = {
    enable = true;
    user = "jacksonb";
    configDir = "/home/jacksonb/.config/syncthing";
  };

  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      package = pkgs.unstable.podman;
      extraRuntimes = with pkgs.unstable; [
        crun
      ];
      defaultNetwork.settings.dns_enabled = true;
    };
    docker = {
      enable = true;
      package = pkgs.unstable.docker;
    };
  };

  fileSystems = {
    "/".options = [
      "compress=zstd"
      "noatime"
    ];
  };

  # TODO: Organize and compartmentalize this
  environment.systemPackages = with pkgs; [
    config.boot.kernelPackages.cpupower
    file
    traceroute
    unstable.kanata-with-cmd
    btop
    gtypist
    gcc
    gnumake
    bc
    gdb
    unstable.neovim
    unstable.neovide
    unstable.evil-helix
    p7zip
    bat
    unstable.qalculate-gtk
    man-pages
    man-pages-posix
    mimeo
    handlr-regex # Updated, Rust-based mimeo alternative
    ffmpeg
    gtypist
    fprintd
    brightnessctl
    qmk
    qmk-udev-rules
    rclone
    playerctl
    libinput
    libportal
    gnuplot
    yt-dlp
    usbutils
    gtk3
    libsForQt5.qt5.qtwayland
    libsForQt5.qtstyleplugins
    tlrc
    nixfmt
    kdePackages.krdc
    distrobox
    unstable.hugo
    sshfs
    unstable.oh-my-posh
    git-filter-repo
    aha
    pwgen
    unstable.obs-studio
    unstable.tree-sitter
    unstable.ventoy
    unstable.opentofu
    unstable.tofu-ls
    inkscape
    librsvg # Needed for proper Inkscape PDF exports (hyprlinks)
    gimp3
    gjs
    flatpak-builder
    meson
    cmake
    egl-wayland
    pkg-config
    wayland-scanner
    wayland
    unstable.atuin

    eog
    gucharmap
    zathura
    (texliveMedium.withPackages (
      texlive-packages: with texlive-packages; [
        biblatex
        enumitem
        multirow
        pgfplots
        titling
      ]
    ))
    wl-clipboard
    nwg-look
    unstable.calibre
    libreoffice-fresh
    (unstable.rofi.override {
      plugins = [
        unstable.rofi-calc
      ];
    })
    gnome-software

    glib
    unstable.moonlight-qt
    adwaita-icon-theme
    zoom-us
    overskride
    unstable.ddcutil
    hyprpicker
    hyprpolkitagent
    polkit_gnome
    via
    syncthingtray
    vscodium
    android-file-transfer
    unstable.openscad-lsp
    (unstable.callPackage ../packages/kotlin-lsp.nix { })
    xdotool

    grim # TODO: Consider replacing with https://github.com/eriedaberrie/grim-hyprland
    slurp
    wf-recorder

    nordic

    vlc
    unstable.kitty
    networkmanagerapplet
    unstable.tailscale

    kdePackages.qtsvg
    kdePackages.qtwayland

    kdePackages.dolphin
    kdePackages.filelight

    pavucontrol
    gparted
    udiskie

    unstable.obsidian

    # VCS
    lazygit
    unstable.jujutsu
    git-credential-manager

    # Secrets
    (pass.override {
      waylandSupport = true;
    })
    seahorse
    gnupg
    pinentry-gnome3

  ];

  fonts = {
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      noto-fonts
    ];
    enableDefaultPackages = true;
  };

  environment.sessionVariables = {
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";

    PATH = [
      "$HOME/.npm-global/bin"
      "$XDG_DATA_HOME/pnpm/bin"
      "$HOME/.deno/bin"
      "$HOME/go/bin"
      "$HOME/.cargo/bin"
    ];

    EDITOR = "nvim";
    ZDOTDIR = "$XDG_CONFIG_HOME/zsh";
    NIXOS_OZONE_WL = "1";
    STEAM_FORCE_DESKTOPUI_SCALING = "1.2";

    GTK_THEME = "Nordic";

    POWERSHELL_UPDATECHECK = "Off"; # Disable PowerShell's update notification; is this worth making a PR for?
  };

  environment.localBinInPath = true;

  services.openssh.enable = true;

  services.tailscale = {
    enable = true;
    package = pkgs.unstable.tailscale;
  };

  services.gnome.gnome-keyring.enable = true;
  services.gvfs.enable = true;

  # DO NOT CHANGE THIS. For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion
  system.stateVersion = "24.05"; # Did you read the comment?
}
