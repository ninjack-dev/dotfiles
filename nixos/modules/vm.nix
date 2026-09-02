{
  lib,
  ...
}:
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
    services.k3s.enable = lib.mkForce false;

    boot.loader.grub.useOSProber = lib.mkForce false;
    boot.loader.grub.configurationLimit = lib.mkForce 5;

    programs.hyprland.enable = lib.mkForce false;
    programs.hyprlock.enable = lib.mkForce false;
    services.hypridle.enable = lib.mkForce false;
    systemd.user.services.hyprpolkitagent.enable = lib.mkForce false;

    virtualisation.memorySize = 4096;
    virtualisation.cores = 4;
    virtualisation.diskSize = 10000;
    virtualisation.graphics = false;

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
