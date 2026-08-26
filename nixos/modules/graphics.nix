{
  pkgs,
  inputs,
  ...
}:
let
  # Simple switch between Hyprland flake and nixpkgs.
  useHyprFlake = false;
  hypr =
    if useHyprFlake then
      inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}
      // inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}
    else
      pkgs.unstable;
in
{
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

  programs.dconf.enable = true;

  programs.localsend.enable = true;

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    package = hypr.hyprland;
    portalPackage = hypr.xdg-desktop-portal-hyprland;
  };
  programs.hyprlock.enable = true;
  services.hypridle.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };

  programs.kdeconnect.enable = true;

  programs.thunderbird.enable = true;

  hardware.graphics = {
    enable = true;
    package = hypr.mesa;
    enable32Bit = true;
    package32 = hypr.pkgsi686Linux.mesa;
    # These are also handled by nixos-hardware: https://github.com/NixOS/nixos-hardware/blob/master/common/gpu/intel/default.nix
    extraPackages = with pkgs; [
      intel-media-driver
      vpl-gpu-rt
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [ intel-vaapi-driver ];
  };

  systemd.user.services.hyprpolkitagent = {
    description = "Hyprland Polkit Agent";
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
      Restart = "on-failure";
      TimeoutStopSec = "5sec";
      Slice = "session.slice";
    };
  };

  qt.enable = true;

  environment.systemPackages = with pkgs; [
    (activitywatch.override {
      extraWatchers = with pkgs; [ aw-watcher-window-wayland ];
    })
    (builtins.getFlake "path:/home/jacksonb/.config/ags").packages."x86_64-linux".default # Crappy desktop shell, will be replaced (and this garbage stripped out)
  ];
}
