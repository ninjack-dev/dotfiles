{
  lib,
  pkgs,
  inputs,
  ...
}:
let
  # TODO:
  # - Convert this to a nixpkgs overlay
  # or
  # - Convert any other overrides (e.g. Rofi) to a top level attribute "overload" "unsure of the name"
  # brave = pkgs.brave.override {
  #   commandLineArgs = "--enable-features=TouchpadOverscrollHistoryNavigation";
  # };

  # https://github.com/basecamp/omarchy/issues/2184
  # Locked on version 1.82.170 for now.
  brave = (
    (builtins.getFlake "github:nixos/nixpkgs/51c8f9cfaae8306d135095bcdb3df9027f95542d")
    .legacyPackages.x86_64-linux.brave.override
      { commandLineArgs = "--enable-features=TouchpadOverscrollHistoryNavigation"; }
  );
in
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

  programs.nix-ld = {
    enable = true;
  };

  programs.command-not-found.enable = false;
  programs.nix-index = {
    enable = true;
  };

  hardware.graphics = {
    enable = true;
    package = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.mesa;
    enable32Bit = true;
    package32 =
      inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.pkgsi686Linux.mesa;
    extraPackages = with pkgs; [
      intel-media-driver # For Broadwell (2014) or newer processors. LIBVA_DRIVER_NAME=iHD
      # intel-ocl
      # unstable.intel-media-driver # For Broadwell (2014) or newer processors. LIBVA_DRIVER_NAME=iHD
      # unstable.intel-ocl
    ];
  };

  programs.gnupg.agent.enable = true;

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

  # The E14 gen 6 nixos-hardware module apparently enables TLP.
  # TODO: Determine if replacing TLP with auto-cpufreq is ideal.
  # services.auto-cpufreq.enable = true;

  services.netbird = {
    enable = true;
    package = pkgs.unstable.netbird;
    ui = {
      enable = true;
      package = pkgs.unstable.netbird-ui;
    };
  };

  services.flatpak.enable = true;
  systemd.services.flatpak-repo = {
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.flatpak ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
      flatpak remote-add --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo 
    '';
  };

  networking.firewall = {
    enable = true;
    allowedTCPPortRanges = [
      {
        from = 3000;
        to = 3005;
      }
    ];
    allowedUDPPortRanges = [
    ];
    allowedTCPPorts = [
      80
      443
      8080
      9090 # Calibre wireless connection
      65530 # audio-share https://github.com/mkckr0/audio-share
    ];
    allowedUDPPorts = [
      8080
      9090
      65530 # audio-share https://github.com/mkckr0/audio-share
      54982 # Calibre's discovery protocol
      48123
      39001
      44044
      59678
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
    package = pkgs.appimage-run.override {
      extraPkgs =
        pkgs: with pkgs; [
          libthai
        ];
    };
  };

  programs.kdeconnect.enable = true;

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage =
      inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
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

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        DiscoverableTimeout = 0;
      };
    };
  };

  services.pipewire = {
    enable = true;
    pulse.enable = true;
    jack.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };

  programs.localsend.enable = true;

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
  programs.fish.enable = true;

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
    # When the Brave/Chromium hash changes, all PWA desktop files break. This ensures that when updating Brave, any PWAs installed between the last rebuild and now get updated with the proper bin paths.
    # Notably, this uses the second layer of wrappers; if this were somehow the start of the Brave instance, it would bypass the Wayland/trackpad flags. A more complicated regex would be required to fix this, specifically one that targets both `brave-browser` and `brave` in the `Exec` field
    # TODO:
    # - Put this in its own module alongside brave.
    updateBravePWAs = {
      text = ''
        find "$HOME/.local/share/applications/" -name "brave-*.desktop" -type f -exec ${pkgs.gnused}/bin/sed -i 's|^Exec=.*/brave-browser|Exec=${brave}/opt/brave.com/brave/brave-browser|' {} \;
      '';
    };
    setNpmBinDirectory = {
      text = ''
        ${pkgs.nodejs}/bin/npm set prefix $HOME/.npm-global 
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
      "podman"
      "dialout"
    ];
    shell = pkgs.zsh;
  };
  nixpkgs.config.allowUnfree = true;

  # Disable default `l`, `ll` aliases
  environment.shellAliases = lib.mkForce { };

  services.syncthing = {
    enable = true;

    # TODO: Figure out how to prepend my system username to these paths
    user = "jacksonb";
    configDir = "/home/jacksonb/.config/syncthing";
  };

  documentation.dev.enable = true; # Lets us use man 3

  qt = {
    enable = true;
    # platformTheme = lib.mkForce "gtk2";
    # style = lib.mkForce "gtk2";
  };

  programs.gamescope = {
    enable = true;
    package = pkgs.unstable.gamescope;
    capSysNice = false; # this is unavailable for now, sadly
    args = [
      "--expose-wayland"
    ];
  };

  programs.steam = {
    enable = true;
    package = pkgs.unstable.steam;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    gamescopeSession.enable = true;
    extraPackages = with pkgs; [
      # Needed for Gamescope session?
      coreutils
    ];
  };

  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      package = pkgs.unstable.podman;
      defaultNetwork.settings.dns_enabled = true;
    };
    docker = {
      enable = true;
      package = pkgs.unstable.docker;
    };
  };

  # This caused my system to be unbootable.
  #  fileSystems."/home/jacksonb/OneDrive" = {
  #    device = "OneDrive:";
  #    fsType = "rclone";
  #    options = [
  #      "vfs-cache-mode=writes"
  #      "config=/etc/rclone-mnt.conf"
  #    ];
  #  };

  nixpkgs.overlays = [
    (self: super: {
      rofi = pkgs.unstable.rofi.override {
        rofi-unwrapped = (pkgs.unstable.callPackage ./modules/rofi.nix { });
      };
    })
  ];

  environment.systemPackages = with pkgs; [

    # Shell Apps
    gnupg
    pinentry
    stow
    linuxKernel.packages.linux_zen.cpupower
    gum
    iptables
    unstable.nushell
    blesh
    file
    unstable.powershell
    unstable.powershell-editor-services
    zsh
    traceroute
    unstable.kanata-with-cmd
    nurl
    fzf
    wget
    tmux
    zoxide
    btop
    unstable.pay-respects
    git
    unstable.gh
    psmisc # fuser, pstree
    unzip
    gtypist
    gcc
    gnumake
    bc
    gdb
    bind
    unstable.neovim
    unstable.neovide
    unstable.evil-helix
    p7zip
    valgrind
    bat
    unstable.libqalculate
    unstable.qalculate-gtk
    man-pages
    man-pages-posix
    mimeo
    handlr-regex # Updated, Rust-based mimeo alternative
    ffmpeg
    gtypist
    fprintd
    socat
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
    ripgrep
    fd
    nixfmt-rfc-style
    kdePackages.krdc
    distrobox
    hugo

    inkscape
    librsvg # Needed for proper Inkscape PDF exports (hyprlinks)

    brave

    (activitywatch.override {
      extraWatchers = with pkgs; [ aw-watcher-window-wayland ];
    })

    # unstable.godot-mono # Unusuable until Dotnet is able to access libicu; this is addressed in my module
    (unstable.callPackage ./modules/godot-mono.nix { })

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
    (rofi.override {
      plugins = [
        unstable.rofi-calc
      ];
    })
    gnome-software

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
    yq-go
    syncthingtray
    vscodium
    android-file-transfer
    freecad-wayland
    # unstable.openscad-unstable
    unstable.openscad-lsp
    (unstable.callPackage ./modules/kotlin-lsp.nix { })
    xdotool # Needed for Steam https://wiki.hyprland.org/Configuring/Uncommon-tips--tricks/#minimize-steam-instead-of-killing

    grim # https://sr.ht/~emersion/grim/ TODO: Replace with https://github.com/eriedaberrie/grim-hyprland
    slurp # https://github.com/emersion/slurp?tab=readme-ov-file
    wf-recorder # https://github.com/ammen99/wf-recorder

    # The following is impure since it is not a locked reference, or something, meaning
    # we need to build with --impure. I'm not sure if it's even possible to get it properly locked
    # using only getFlake, opting for a flake input instead. For now, --impure is fine, and is included
    # in the nixos-rebuild custom command.
    # TODO: Put this in my actual flake so that it can get version locked, or somehow make it follow my system flake
    (builtins.getFlake "path:/home/jacksonb/.config/ags").packages."x86_64-linux".default
    nordic

    # Graphical Apps
    vlc
    d-spy
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

    # TODO: Put this in its own module with auto update functionality
    (obsidian.overrideAttrs (
      final: prev: rec {
        version = "1.9.14";
        filename = "obsidian-${version}.tar.gz";
        src = fetchurl {
          url = "https://github.com/obsidianmd/obsidian-releases/releases/download/v${version}/${filename}";
          hash = "sha256-vS8PCz8dpMFvJCF1Heu2m+Qj9hl2ZmxNM0AwB6CbU88=";
        };
      }
    ))
    (unstable.discord.override {
      withVencord = true;
    })

    gimp3

    # Development
    nodejs
    deno
    (pkgs.python3.withPackages (
      python-pkgs: with python-pkgs; [
        pandas
        requests
        tkinter
      ]
    ))
    black
    (perl.withPackages (
      perl-pkgs: with perl-pkgs; [
        NetDBus
      ]
    ))
    unstable.go
    lua
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

    lazygit

    unstable.mongodb-compass
    unstable.mongosh

    hydra-check

    # language servers
    lua-language-server
    clang-tools
    nixd
    vscode-langservers-extracted
    yaml-language-server
    awk-language-server
    pyright
    taplo
    unstable.tombi
    hyprls
    vala-language-server
    perlnavigator

    # TODO: Test if removing these speeds up evaluation time
    nodePackages.typescript-language-server
    nodePackages.bash-language-server

    unstable.rustc
    unstable.cargo
    unstable.rustfmt
    unstable.clippy
    unstable.rust-analyzer

    unstable.obs-studio

    podman-desktop

    unstable.tree-sitter

    unstable.zig
    unstable.zls

    unstable.ventoy

    unstable.csharp-ls
    (
      with unstable.dotnetCorePackages;
      combinePackages [
        sdk_9_0_1xx
      ]
    )

    # unstable.gamescope
    # Gamescope v3.16.4 is the only one that works on Hyprland right now (8/28/25)
    # (import (builtins.fetchTarball {
    #   url = "https://github.com/NixOS/nixpkgs/archive/3e2cf88148e732abc1d259286123e06a9d8c964a.tar.gz";
    # }) { }).gamescope
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
  ];
  fonts.enableDefaultPackages = true;

  # Neither environment.variables or environment.sessionVariables can export these during a login session post-rebuild
  # or at least not that I've found. A relogin is required
  environment.sessionVariables = {
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";

    PATH = [
      "$HOME/.npm-global/bin"
      "$HOME/go/bin"
      "$HOME/.cargo/bin"
    ];

    EDITOR = "nvim";
    ZDOTDIR = "$XDG_CONFIG_HOME/zsh";
    COPY_UTIL = "wl-copy";
    NIXOS_OZONE_WL = "1";
    STEAM_FORCE_DESKTOPUI_SCALING = "1.2"; # Unfortunately, this also applies to monitors that don't need it.
    LIBVA_DRIVER_NAME = "iHD";

    POWERSHELL_UPDATECHECK = "Off"; # Disable PowerShell's update notification; is this worth making a PR for?
  };

  environment.localBinInPath = true;

  services.openssh.enable = true;

  services.ollama = {
    enable = true;
  };

  # DO NOT CHANGE THIS. For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion
  system.stateVersion = "24.05"; # Did you read the comment?
}
