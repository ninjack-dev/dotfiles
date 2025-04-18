{
  config,
  lib,
  pkgs,
  inputs,
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

  # The following are for programs that I have yet to wrap for myself.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # Used for audio-share
      pipewire
      glibc

      # Needed for Godot
      (
        with pkgs.dotnetCorePackages;
        combinePackages [
          sdk_8_0
        ]
      )
      alsa-lib
      libGL
      vulkan-loader
      xorg.libX11
      xorg.libXcursor
      xorg.libXext
      xorg.libXfixes
      xorg.libXi
      xorg.libXinerama
      libxkbcommon
      xorg.libXrandr
      xorg.libXrender
      libdecor
      wayland
      dbus
      dbus.lib
      fontconfig
      fontconfig.lib
      libpulseaudio
      speechd-minimal
      udev
    ];
  };
  # programs.nix-index.enable = true;
  programs.command-not-found.enable = true;

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # For Broadwell (2014) or newer processors. LIBVA_DRIVER_NAME=iHD
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
  };

  hardware.i2c.enable = true;
  hardware.keyboard.qmk.enable = true;

  boot.supportedFilesystems = [ "ntfs" ];

  networking.hostName = "nixos-laptop"; # Define your hostname.
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

  # This service works only when using UWSM, which sets graphical-session.target
  # systemd.user.services.polkit-gnome-authentication-agent-1 = {
  #   description = "polkit-gnome-authentication-agent-1";
  #   wantedBy = ["graphical-session.target"];
  #   wants = ["graphical-session.target"];
  #   after = ["graphical-session.target"];
  #
  #   serviceConfig = {
  #     Type = "simple";
  #     ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
  #     Restart = "on-failure";
  #     RestartSec = 1;
  #     TimeoutStopSec = 10;
  #   };
  # };

  # See if I can replace this with security.sudo.extraRules later
  # security.sudo.extraConfig = ''
  #   Defaults        env_reset,timestamp_timeout=15,fingerprint
  # '';

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
    rebuild = "sudo nixos-rebuild switch --impure && notify-send --icon=nix-snowflake --app-name='NixOS Rebuild' 'Rebuild complete.' || notify-send --icon=nix-snowflake --app-name='NixOS Rebuild' 'Rebuild failed!'";
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
    updateBravePWAs.text = ''
      find "$HOME/.local/share/applications/" -name "brave-*.desktop" -type f -exec sed -i 's|^Exec=.*/brave-browser|Exec=${pkgs.brave}/opt/brave.com/brave/brave-browser|' {} \;
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

  environment.systemPackages = with pkgs; [

    # Shell Apps
    linuxKernel.packages.linux_zen.cpupower
    xxd
    fish
    nushell
    file
    unstable.powershell
    zsh
    traceroute
    unstable.oh-my-posh
    fzf
    wget
    tmux
    zoxide
    btop
    pay-respects
    git
    gh
    unzip
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
    mimeo # Attempt to register new handler
    ffmpeg
    fprintd
    socat
    brightnessctl
    qmk
    playerctl
    libinput
    libportal # Test for Gtk
    gnuplot
    yt-dlp
    usbutils
    gtk3 # Needed for gtk-launch
    libsForQt5.qt5.qtwayland # Test fix for broken Freecad display
    libsForQt5.qtstyleplugins
    tlrc
    ripgrep
    nixfmt-rfc-style
    inkscape

    # Desktop Environment Apps
    eog # Image Viewer
    unstable.input-leap
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
        # I wonder if the version override happens automatically. Probably not.
        (unstable.rofi-calc.override {
          rofi-unwrapped = unstable.rofi-wayland-unwrapped;
        })
      ];
    })
    gnome-software

    openssl # school

    # (godot_4-mono.override {
    #   dotnet-sdk_6 = dotnet-sdk_8;
    # })
    unstable.bambu-studio
    libnotify
    glib
    vala
    unstable.moonlight-qt
    adwaita-icon-theme
    zoom-us
    overskride
    hyprpicker
    hyprpolkitagent
    polkit_gnome
    via
    wev
    jq
    syncthingtray
    vscodium # Only here for a slightly improved Markdown rendering/editing experience. And Git.
    android-file-transfer
    freecad-wayland
    unstable.openscad-unstable
    unstable.openscad-lsp
    xdotool # Needed for Steam https://wiki.hyprland.org/Configuring/Uncommon-tips--tricks/#minimize-steam-instead-of-killing

    grim # https://sr.ht/~emersion/grim/
    slurp # https://github.com/emersion/slurp?tab=readme-ov-file
    wf-recorder # https://github.com/ammen99/wf-recorder

    # (inputs.ags.packages.${system}.default)
    # The following is impure since it is not a locked reference, or something, meaning
    # we need to build with --impure. I'm not sure if it's even possible to get it properly locked
    # using only getFlake, opting for a flake input instead. For now, --impure is fine, and is included
    # in the nixos-rebuild custom command.
    # TODO: Put this in my actual flake so that it can get version locked.
    (builtins.getFlake "path:/home/jacksonb/.config/ags").packages."x86_64-linux".default
    d-spy
    nordic

    # Graphical Apps
    rustdesk
    brave
    vlc
    kitty
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
    go
    gopls
    gjs
    # dotnet-sdk_9
    # dotnet-sdk_8 # Debugging csharp-ls
    flatpak-builder

    wireshark

    meson
    cmake
    egl-wayland
    pkg-config
    wayland-scanner
    wayland

    unstable.mongodb-compass # Work
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
    # TODO - Figure out how to get these outta here. Since I can't use NPM to install globally,
    # these packages have to get pulled from that one gigantic Nixpkgs module, which as far as I can
    # tell greatly increases my evaluation time since it's like 20k lines.
    nodePackages.typescript-language-server
    nodePackages.bash-language-server
    unstable.csharp-ls # Needs to be unstable until fix is pulled into 24.11

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
  # We need rec to allow variables to be used in the block, apparently. See https://nix.dev/guides/best-practices#recursive-attribute-set-rec
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
    # WLR_NO_HARDWARE_CURSORS = "1";
    LIBVA_DRIVER_NAME = "iHD";
  };

  environment.localBinInPath = true;

  services.openssh.enable = true;

  services.ollama = {
    enable = true;
    acceleration = "cuda";
  };

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.05"; # Did you read the comment?

}
