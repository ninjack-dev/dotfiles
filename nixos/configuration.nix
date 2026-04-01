{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:
{
  disabledModules = [
    "services/networking/netbird.nix"
  ];
  imports = [
    ./hardware-configuration.nix
    "${inputs.nixpkgs-unstable}/nixos/modules/services/networking/netbird.nix"
  ];
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
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
    # These are handled by nixos-hardware: https://github.com/NixOS/nixos-hardware/blob/master/common/gpu/intel/default.nix
    # extraPackages = with pkgs; [
    #   intel-media-driver
    #   vpl-gpu-rt
    # ];
    # extraPackages32 = with pkgs; [
    #   intel-vaapi-driver
    # ];
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
  services.logind.settings.Login.HandleLidSwitch = "suspend";
  services.logind.settings.Login.HandleLidSwitchDocked = "suspend";

  services.chrony.enable = true;

  services.envfs.enable = true;

  services.resolved = {
    enable = true;
    extraConfig = "ResolveUnicastSingleLabel=yes";
  };

  # The nixos-hardware module apparently enables TLP.
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
  # systemd.services.flatpak-repo = {
  #   wantedBy = [ "multi-user.target" ];
  #   wants = [ "network-online.target" ];
  #   path = [ pkgs.flatpak ];
  #   script = ''
  #     flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  #     flatpak remote-add --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo
  #   '';
  # };

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
      8000
      9090 # Calibre wireless connection
      65530 # audio-share https://github.com/mkckr0/audio-share
    ];
    allowedUDPPorts = [
      8000
      9090
      65530 # audio-share https://github.com/mkckr0/audio-share
      54982 # Calibre's discovery protocol
    ];
  };

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

  # The Kanata services cannot load $HOME-bound configuration files without this. See issue 404687.
  systemd.services.kanata-thinkpad.serviceConfig = {
    ProtectHome = lib.mkForce "read-only";
    DynamicUser = lib.mkForce false;
    User = lib.mkForce "jacksonb";
  };

  hardware.i2c.enable = true;
  hardware.keyboard.qmk.enable = true;

  boot.supportedFilesystems = [ "ntfs" ];

  networking.hostName = "nixos-laptop";
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
  };

  programs.zsh.enable = true;
  programs.fish.enable = true;

  services.dbus = {
    enable = true;
    packages = with pkgs; [ dconf ];
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

  environment.shellAliases = lib.mkForce { }; # Disable default `l`, `ll` aliases

  services.syncthing = {
    enable = true;
    user = "jacksonb";
    configDir = "/home/jacksonb/.config/syncthing";
  };

  documentation.dev.enable = true;

  qt = {
    enable = true;
  };

  programs.gamescope = {
    enable = true;
    package = pkgs.unstable.gamescope;
    capSysNice = false;
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
      coreutils # Needed for Gamescope session
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

  fileSystems = {
    "/".options = [
      "compress=zstd"
      "noatime"
    ];
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
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

  environment.systemPackages = with pkgs; [
    # Shell Apps
    gnupg
    pinentry-gnome3
    stow
    config.boot.kernelPackages.cpupower
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
    unstable.gh
    psmisc # Provides fuser, pstree
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
    sshfs

    inkscape
    librsvg # Needed for proper Inkscape PDF exports (hyprlinks)

    (brave.override {
      commandLineArgs = "--enable-features=TouchpadOverscrollHistoryNavigation";
    })

    (activitywatch.override {
      extraWatchers = with pkgs; [ aw-watcher-window-wayland ];
    })

    (unstable.callPackage ./modules/godot-mono.nix { })

    # Desktop Environment Apps
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
    calibre
    libreoffice-fresh
    (unstable.rofi.override {
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
    polkit_gnome
    via
    wev
    jq
    yq-go
    syncthingtray
    vscodium
    android-file-transfer
    unstable.openscad-lsp
    (unstable.callPackage ./modules/kotlin-lsp.nix { })
    xdotool # Needed for Steam https://wiki.hyprland.org/Configuring/Uncommon-tips--tricks/#minimize-steam-instead-of-killing

    grim # TODO: Consider replacing with https://github.com/eriedaberrie/grim-hyprland
    slurp
    wf-recorder

    (builtins.getFlake "path:/home/jacksonb/.config/ags").packages."x86_64-linux".default
    nordic

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

    (unstable.obsidian.overrideAttrs (
      final: prev: {
        buildInputs = prev.buildInputs ++ [
          asar
          jq
        ];
        postPatch = ''
          mkdir app
          asar extract ./resources/app.asar ./app
          mv ./app/package.json ./package.json.old
          jq '.desktopName = "obsidian"' ./package.json.old > ./app/package.json
          asar pack ./app ./resources/app.asar
          rm -r ./app ./package.json.old
        '';
      }
    ))

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

    hydra-check

    lua-language-server
    clang-tools
    nixd
    vscode-langservers-extracted
    yaml-language-server
    awk-language-server
    pyright
    taplo
    unstable.tombi
    vala-language-server
    perlnavigator
    typescript-language-server
    bash-language-server

    unstable.rustc
    unstable.cargo
    unstable.rustfmt
    unstable.clippy
    unstable.rust-analyzer

    unstable.obs-studio

    unstable.forgejo-cli

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
        sdk_10_0-bin
      ]
    )
    git-credential-manager

    (pass.override {
      waylandSupport = true;
    })

    seahorse
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

  services.gnome.gnome-keyring.enable = true;
  services.gvfs.enable = true;

  # DO NOT CHANGE THIS. For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion
  system.stateVersion = "24.05"; # Did you read the comment?
}
