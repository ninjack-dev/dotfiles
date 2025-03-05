{ config, lib, pkgs, inputs, ... }:
{
  imports =
    [
      ./hardware-configuration.nix
    ];
  nix.settings.experimental-features =
    [
      "nix-command"
      "flakes"
    ];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 2w";
  };

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

  # services.tlp.enable = true;
  services.auto-cpufreq.enable = true;

  services.flatpak.enable = true;
  systemd.services.flatpak-repo = {
    wantedBy = ["multi-user.target"];
    path = [pkgs.flatpak];
    script = ''
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpak-repo
    '';
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

  # See if I can replace this with security.sudo.extraRules later
  # security.sudo.extraConfig = ''
  #   Defaults        env_reset,timestamp_timeout=15,fingerprint
  # '';
  
  networking.networkmanager.enable = true;

  time.timeZone = "America/Los_Angeles";

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      dotnet-sdk_8
      wayland
    ];
  };

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

  programs.direnv.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; 
      [
        xdg-desktop-portal-gtk
      ];
    xdgOpenUsePortal = true;
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
  
  users.users.jacksonb = {
    isNormalUser = true;
    extraGroups = [ "wheel" "audio" "networkmanager" "sudo" "docker" "dialout"]; 
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

  qt.enable = true;
  # qt.platformTheme = "gtk2";
  # qt.style = "gtk2";

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  };

  virtualisation.docker.enable = true;

  environment.systemPackages = with pkgs; [

  # Shell Apps
    steghide
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
    thefuck
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
    xdg-utils
    mimeo # Attempt to register new handler
    ffmpeg
    fprintd
    socat
    brightnessctl
    qmk
    playerctl
    gnuplot
    yt-dlp
    usbutils
    gtk3 # Needed for gtk-launch
    libsForQt5.qt5.qtwayland # Test fix for broken Freecad display
    tlrc
    ripgrep

  # Desktop Environment Apps
    unstable.input-leap
    zathura
    (texliveMedium.withPackages (texlive-packages: with texlive-packages; [ 
      enumitem
      multirow
    ]))
    wl-clipboard
    nwg-look
    calibre
    libreoffice-fresh
    # clipboard-jh # Waiting for https://github.com/Slackadays/Clipboard/issues/171
    rofi-wayland
    (rofi-calc.override {
      rofi-unwrapped = rofi-wayland-unwrapped;
    })
    # unstable.bambu-studio # This broke my build for some reason?
    libnotify
    glib
    unstable.moonlight-qt
    # gnome.adwaita-icon-theme
    adwaita-icon-theme
    zoom-us
    overskride
    thunderbird # When 24.11 launches, update this to use programs.thunderbird
    hyprpicker
    via
    wev
    jq
    syncthingtray
    vscodium # Only here for a slightly improved Markdown rendering/editing experience. And Git. 
    android-file-transfer
    freecad-wayland
    openscad-unstable
    openscad-lsp
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
    firefox
    vlc
    kitty
    networkmanagerapplet
    nwg-displays

    kdePackages.dolphin
    kdePackages.qtsvg
    kdePackages.qtwayland

    pavucontrol
    gparted
    udiskie

    # Electron
    obsidian
    discord

  # Development
    nodejs
    (pkgs.python3.withPackages (python-pkgs: with python-pkgs; [
      # select Python packages here
      pandas
      requests
    ]))
    go
    gopls
    gjs # AGS stuff
    dotnet-sdk_9
    # godot_4-mono # Dotnet 6 is apparently insecure, meaning I can't use this :/
    flatpak-builder

    wireshark

    meson
    cmake
    egl-wayland
    pkg-config
    wayland-scanner
    wayland
    
    unstable.mongodb-compass # Work

    # language servers
    lua-language-server
    clang-tools
    nil
    vscode-langservers-extracted
    pyright
    taplo
    hyprls
  # TODO - Figure out how to get these outta here. Since I can't use NPM to install globally,
  # these packages have to get pulled from that one gigantic Nixpkgs module, which as far as I can 
  # tell greatly increases my evaluation time since it's like 20k lines.
    nodePackages.typescript-language-server
    nodePackages.bash-language-server
    csharp-ls

    arduino-cli
    arduino-language-server
    arduino-ide

  ];

  
  fonts.packages = with pkgs; [
    (nerdfonts.override {fonts = [ "JetBrainsMono" "FiraCode"]; } )
  ];

  # Neither environment.variables or environment.sessionVariables can export these during a login session post-rebuild
  # or at least not that I've found. A relogin is required
  # We need rec to allow variables to be used in the block, apparently. See https://nix.dev/guides/best-practices#recursive-attribute-set-rec
  environment.sessionVariables = {
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_CACHE_HOME  = "$HOME/.cache";
    XDG_DATA_HOME   = "$HOME/.local/share";
    XDG_STATE_HOME  = "$HOME/.local/state";

    EDITOR = "nvim";
    ZDOTDIR = "$XDG_CONFIG_HOME/zsh";
    COPY_UTIL = "wl-copy";
    NIXOS_OZONE_WL = "1";
    STEAM_FORCE_DESKTOPUI_SCALING = "1.6"; # Unfortunately, this also applies to monitors that don't need it. 
    # WLR_NO_HARDWARE_CURSORS = "1";
  };

  environment.localBinInPath = true;

  services.openssh.enable = true;

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
