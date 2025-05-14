{
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
  ];
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 2w";
  };

  programs.nix-ld.enable = true;

  hardware.graphics = {
    enable = true;
    # package = pkgs.unstable.mesa.drivers;
    # package32 = pkgs.unstable.pkgsi686Linux.mesa;
    extraPackages = with pkgs; [
      intel-media-driver # For Broadwell (2014) or newer processors. LIBVA_DRIVER_NAME=iHD
      # intel-ocl
      # unstable.intel-media-driver # For Broadwell (2014) or newer processors. LIBVA_DRIVER_NAME=iHD
      # unstable.intel-ocl
    ];
  };

  boot.kernelPackages = pkgs.linuxKernel.packages.linux_zen;

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.useOSProber = true;
  boot.loader.grub.configurationLimit = 30;

  boot.tmp.cleanOnBoot = true;
  services.logind.lidSwitch = "suspend";
  services.logind.lidSwitchDocked = "suspend";

  services.chrony.enable = true;

  services.envfs.enable = true;

  # services.tlp.enable = true;
  services.auto-cpufreq.enable = true;

  services.flatpak.enable = true;
  systemd.services.flatpak-repo = {
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.flatpak ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    '';
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      80
      443
      8080
      65530 # audio-share https://github.com/mkckr0/audio-share
    ];
    allowedUDPPorts = [
      65530 # audio-share https://github.com/mkckr0/audio-share
    ];
  };

  # https://wiki.nixos.org/wiki/Printing
  services.printing.enable = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  services.kanata = {
    enable = true;
    package = pkgs.unstable.kanata-with-cmd;
    keyboards.thinkpad.configFile = "/home/jacksonb/.config/kanata/thinkpad.kbd";
  };

  # Waiting for https://github.com/NixOS/nixpkgs/issues/404687
  # https://discourse.nixos.org/t/overriding-options-in-systemd-units-generated-by-nixos/13755/2
  systemd.services.kanata-thinkpad.serviceConfig = {
    ProtectHome = lib.mkForce "read-only";
    DynamicUser = lib.mkForce false;
    User = lib.mkForce "jacksonb";
  };

  hardware.i2c.enable = true;
  hardware.keyboard.qmk.enable = true;

  boot.supportedFilesystems = [ "ntfs" ];

  networking.hostName = "nixos-laptop";
  # TODO - Debug why this rule isn't working.
  security.polkit.enable = true;
  security.polkit.extraConfig = ''
    /* Don't require sudo for reboot/power-off */
    polkit.addRule(function (action, subject) {
      if (
        subject.isInGroup("users") &&
        [
          "org.freedesktop.login1.reboot",
          "org.freedesktop.login1.reboot-multiple-sessions",
          "org.freedesktop.login1.power-off",
          "org.freedesktop.login1.power-off-multiple-sessions",
        ].indexOf(action.id) !== -1
      ) {
        return polkit.Result.YES;
      }
    });
  '';

  networking.networkmanager.enable = true;

  time.timeZone = "America/Los_Angeles";

  programs.thunderbird.enable = true;

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  programs.kdeconnect.enable = true;

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    # package = pkgs.unstable.hyprland;
  };

  programs.hyprlock.enable = true;
  services.hypridle.enable = true;

  services.udisks2.enable = true;

  programs.direnv = {
    enable = true;
    loadInNixShell = true;
    nix-direnv = {
      enable = true;
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
    # xdgOpenUsePortal = true; # This breaks a LOT when using Mimeo. Must research later.
  };

  programs.zsh.enable = true;
  programs.zsh.shellAliases = {
    nix-edit = "nvim -c \"lcd ~/.config/nixos\" -c NvimTreeToggle";
    nix-develop = "nix develop -c \"zsh\" -c \"export SHELL=zsh; zsh -i\"";
  };

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  hardware.bluetooth.settings = {
    General = {
      Enable = "Source,Sink,Media,Socket";
    };
  };

  services.pipewire = {
    enable = true;
    pulse.enable = true;
    jack.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };

  # May be unnecessary if Hyprland is installed
  services.libinput.enable = true;

  services.dbus = {
    enable = true;
    packages = [ pkgs.dconf ];
  };

  systemd.services.fprintd = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "simple";
  };

  services.fprintd = {
    enable = true;
  };

  services.upower.enable = true;

  system.userActivationScripts = {
    # When the Brave/Chromium hash changes, all PWA desktop files break. This at the very least ensures that when rebuilding the system, any PWAs installed between the last rebuild and now get updated with
    # TODO: Put this in its own module alongside brave.
    updateBravePWAs = {
      text = ''
        find "$HOME/.local/share/applications/" -name "brave-*.desktop" -type f -exec ${pkgs.gnused}/bin/sed -i 's|^Exec=.*/brave-browser|Exec=${pkgs.brave}/opt/brave.com/brave/brave-browser|' {} \;
      '';
    };
  };

  users.users.jacksonb = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "audio"
      "networkmanager"
      "sudo"
      "docker"
      "dialout"
    ];
    shell = pkgs.zsh;
  };
  nixpkgs.config.allowUnfree = true;

  services.syncthing = {
    enable = true;

    # TODO: Figure out how to prepend my system username to these paths
    user = "jacksonb";
    configDir = "/home/jacksonb/.config/syncthing";
  };

  documentation.dev.enable = true; # Lets us use man 3

  qt = {
    enable = true;
    platformTheme = lib.mkForce "gtk2";
    style = lib.mkForce "gtk2";
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    gamescopeSession.enable = true;
    extraPackages = with pkgs; [
      # Needed for Gamescope session?
      coreutils
    ];
  };

  virtualisation.docker.enable = true;
  virtualisation.docker.package = pkgs.docker_28;

  environment.systemPackages = with pkgs; [

    # Shell Apps
    stow
    linuxKernel.packages.linux_zen.cpupower
    iptables
    fish
    nushell
    file
    unstable.powershell
    zsh
    traceroute
    pkgs.unstable.kanata-with-cmd
    # Waiting for https://github.com/NixOS/nixpkgs/issues/404020
    # Using ~/.local/bin/oh-my-posh for now
    # (
    #   (unstable.oh-my-posh.override {
    #     buildGoModule = buildGoModule.override { go = go_1_24; };
    #   }).overrideAttrs
    #   rec {
    #     version = "25.21.0";
    #     src = fetchFromGitHub {
    #       owner = "JanDeDobbeleer";
    #       repo = "oh-my-posh";
    #       rev = "v${version}";
    #       hash = "sha256-0TLAAJIdvO/CnGAG4TN3C54T/RTpjGqNx/oLEsuvWzg=";
    #     };
    #     vendorHash = "sha256-8vc+PfXX+A4+4almazrRIMHd169IQqE8rCaa2aCmB2A=";
    #     postPatch = ''
    #       # these tests requires internet access
    #       rm image/image_test.go \
    #       config/migrate_glyphs_test.go \
    #       upgrade/notice_test.go \
    #       segments/upgrade_test.go # Added this; I'm assuming it was added after the most recent build
    #     '';
    #     # Remove completion installation; https://github.com/JanDeDobbeleer/oh-my-posh/releases/tag/v25.0.0
    #     postInstall = ''
    #       mv $out/bin/{src,oh-my-posh}
    #       mkdir -p $out/share/oh-my-posh
    #       cp -r $src/themes $out/share/oh-my-posh/
    #     '';
    #   }
    # )

    nurl
    fzf
    wget
    tmux
    zoxide
    btop
    unstable.pay-respects
    git
    gh
    unzip
    gtypist
    gcc
    gnumake
    gdb
    bind
    unstable.neovim
    unstable.neovide
    p7zip
    valgrind
    bat
    unstable.libqalculate
    unstable.qalculate-gtk
    man-pages
    man-pages-posix
    mimeo
    ffmpeg
    gtypist
    fprintd
    socat
    brightnessctl
    qmk
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
    ripgrep
    nixfmt-rfc-style
    inkscape

    # unstable.godot-mono # Unusuable until Dotnet is able to access libicu; this is addressed in my module
    (unstable.callPackage ./modules/godot/godot-mono.nix {})

    # Desktop Environment Apps
    eog # Image Viewer
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
    calibre
    libreoffice-fresh
    # clipboard-jh # Waiting for https://github.com/Slackadays/Clipboard/issues/171
    (unstable.rofi-wayland.override {
      plugins = [
        (unstable.rofi-calc.override {
          rofi-unwrapped = unstable.rofi-wayland-unwrapped;
        })
      ];
    })
    gnome-software

    unstable.bambu-studio
    libnotify
    glib
    vala
    unstable.moonlight-qt
    adwaita-icon-theme
    zoom-us
    overskride
    unstable.ddcutil
    hyprpicker
    hyprpolkitagent
    # unstable.hyprpicker
    # unstable.hyprpolkitagent
    polkit_gnome
    via
    wev
    jq
    syncthingtray
    vscodium
    android-file-transfer
    freecad-wayland
    unstable.openscad-unstable
    unstable.openscad-lsp
    xdotool # Needed for Steam https://wiki.hyprland.org/Configuring/Uncommon-tips--tricks/#minimize-steam-instead-of-killing

    grim # https://sr.ht/~emersion/grim/
    slurp # https://github.com/emersion/slurp?tab=readme-ov-file
    wf-recorder # https://github.com/ammen99/wf-recorder

    # The following is impure since it is not a locked reference, or something, meaning
    # we need to build with --impure. I'm not sure if it's even possible to get it properly locked
    # using only getFlake, opting for a flake input instead. For now, --impure is fine, and is included
    # in the nixos-rebuild custom command.
    # TODO: Put this in my actual flake so that it can get version locked, or somehow make it follow my system flake
    (builtins.getFlake "path:/home/jacksonb/.config/ags").packages."x86_64-linux".default
    d-spy
    nordic

    # Graphical Apps
    rustdesk # Consider replacing this with portable binary; updates take 17 years to build
    (brave.override { commandLineArgs = "--enable-features=TouchpadOverscrollHistoryNavigation"; })
    vlc
    unstable.kitty
    networkmanagerapplet
    nwg-displays

    kdePackages.qtsvg
    kdePackages.qtwayland

    kdePackages.dolphin
    kdePackages.filelight

    pavucontrol
    gparted
    udiskie

    # Electron
    obsidian
    discord

    # Development
    nodejs
    (pkgs.python3.withPackages (
      python-pkgs: with python-pkgs; [
        pandas
        requests
        tkinter
      ]
    ))
    (perl.withPackages (
      perl-pkgs: with perl-pkgs; [
        NetDBus
      ]
    ))
    unstable.go
    gopls
    gjs
    flatpak-builder

    wireshark

    meson
    cmake
    egl-wayland
    pkg-config
    wayland-scanner
    wayland

    unstable.mongodb-compass
    unstable.mongosh

    # language servers
    lua-language-server
    clang-tools
    nil
    vscode-langservers-extracted
    pyright
    taplo
    hyprls
    vala-language-server
    # I believe the nodePackages attribute set causes my evaluation type to spike.
    nodePackages.typescript-language-server
    nodePackages.bash-language-server
    unstable.csharp-ls

    arduino-cli
    arduino-language-server
    arduino-ide
  ];

  fonts.packages = with pkgs; [
    (nerdfonts.override {
      fonts = [
        "JetBrainsMono"
        "FiraCode"
      ];
    })
  ];
  fonts.enableDefaultPackages = true;

  # Neither environment.variables or environment.sessionVariables can export these during a login session post-rebuild
  # or at least not that I've found. A relogin is required
  environment.sessionVariables = {
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";

    EDITOR = "nvim";
    ZDOTDIR = "$XDG_CONFIG_HOME/zsh";
    COPY_UTIL = "wl-copy";
    NIXOS_OZONE_WL = "1";
    STEAM_FORCE_DESKTOPUI_SCALING = "1.2"; # Unfortunately, this also applies to monitors that don't need it.
    LIBVA_DRIVER_NAME = "iHD";
  };

  environment.localBinInPath = true;

  services.openssh.enable = true;

  services.ollama = {
    enable = true;
  };

  # DO NOT CHANGE THIS. For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion
  system.stateVersion = "24.05"; # Did you read the comment?
}
