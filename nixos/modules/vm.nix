{
  lib,
  ...
}:
{
  virtualisation.vmVariant = builtins.mapAttrs (_: value: lib.mkVMOverride value) {

    hardware.graphics.enable = false;

    hardware.bluetooth.enable = false;
    hardware.i2c.enable = false;
    hardware.keyboard.qmk.enable = false;

    services.fprintd.enable = false;
    services.kanata.enable = false;
    services.printing.enable = false;
    services.udev.extraRules = "";
    services.k3s.enable = false;

    boot.loader.grub.useOSProber = false;
    boot.loader.grub.configurationLimit = 5;

    programs.hyprland.enable = false;
    programs.hyprlock.enable = false;
    services.hypridle.enable = false;
    systemd.user.services.hyprpolkitagent.enable = false;

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
    networking.dhcpcd.extraConfig = "noarp";
  };
}
