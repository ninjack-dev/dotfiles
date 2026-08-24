{
  lib,
  config,
  ...
}:
# Heavily WIP.
let
  cfg = config.vm;
in
{
  virtualisation.vmVariant = {

    hardware.graphics.enable = lib.mkForce false;

    hardware.bluetooth.enable = lib.mkForce false;
    hardware.i2c.enable = lib.mkForce false;
    hardware.keyboard.qmk.enable = lib.mkForce false;

    services.fprintd.enable = lib.mkForce false;
    services.kanata.enable = lib.mkForce false;
    services.printing.enable = lib.mkForce false;
    services.udev.extraRules = lib.mkForce "";

    boot.loader.grub.useOSProber = lib.mkForce false;
    boot.loader.grub.configurationLimit = lib.mkForce 5;

    programs.hyprland.enable = lib.mkForce false;
    programs.hyprlock.enable = lib.mkForce false;
    services.hypridle.enable = lib.mkForce false;
    systemd.user.services.hyprpolkitagent.enable = lib.mkForce false;

    virtualisation.memorySize = cfg.memorySize;
    virtualisation.cores = cfg.cores;
    virtualisation.diskSize = cfg.diskSize;
    virtualisation.graphics = cfg.graphics;

    virtualisation.forwardPorts = [
      {
        from = "host";
        host.port = 2222;
        guest.port = 22;
      }
    ];

    # For faster boot, avoid waiting for ARP on the virtual NIC.
    networking.dhcpcd.extraConfig = lib.mkForce "noarp";
  };
}
