{
  pkgs,
  lib,
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

  # Adapted from https://github.com/StanAngeloff/nix-meridian/blob/trunk/home/apps/brave/default.nix.
  # Learn more at https://github.com/NixOS/nixpkgs/pull/378184.
  brave =
    let
      enabledFeatures = [
        "Vulkan"
        "DefaultANGLEVulkan"
        "VulkanFromANGLE"
        "VaapiIgnoreDriverChecks"
      ];
    in
    (pkgs.brave.overrideAttrs (prev: {
      preFixup = (prev.preFixup or "") + ''
        gappsWrapperArgs+=(
          --prefix LD_LIBRARY_PATH : "${hypr.vulkan-loader}/lib"
        )
      '';
      postFixup = (prev.postFixup or "") + ''
        substituteInPlace $out/bin/brave \
          --replace-fail "--enable-features=" "--enable-features=${builtins.concatStringsSep "," enabledFeatures},"

        # Replace shipped libvulkan with vulkan-loader's. Using hypr's just in case.
        ln -sf "${hypr.vulkan-loader}/lib/libvulkan.so.1" "$out/opt/brave.com/brave/libvulkan.so.1"
      '';
    })).override
      { libva = hypr.libva; };
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

  # Experimental driver
  hardware.intelgpu.driver = "xe";

  hardware.graphics = {
    enable = true;
    package = hypr.mesa;
    enable32Bit = true;
    package32 = hypr.pkgsi686Linux.mesa;
    # These are typically handled by nixos-hardware: https://github.com/NixOS/nixos-hardware/blob/master/common/gpu/intel/default.nix
    # mkForce fixes merge conflicts when inputs to buildEnv diverge.
    extraPackages = lib.mkForce (
      with hypr;
      [
        intel-media-driver
        vpl-gpu-rt
        intel-compute-runtime
      ]
    );
    extraPackages32 = lib.mkForce (
      with hypr.pkgsi686Linux;
      [
        intel-media-driver
        intel-vaapi-driver
      ]
    );
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
    (brave.override {
      commandLineArgs = "--enable-features=TouchpadOverscrollHistoryNavigation";
    })
  ];
}
