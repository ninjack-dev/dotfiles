{
  lib,
  pkgs,
  config,
  ...
}:

let
  cfg = config.vm;
in
{
  options.vm = {
    enable = lib.mkEnableOption "VM build variant support (via virtualisation.vmVariant)";

    memorySize = lib.mkOption {
      type = lib.types.ints.positive;
      default = 4096;
      description = "Memory size in MiB for the VM";
    };

    cores = lib.mkOption {
      type = lib.types.ints.positive;
      default = 4;
      description = "Number of CPU cores for the VM";
    };

    diskSize = lib.mkOption {
      type = lib.types.ints.positive;
      default = 40960;
      description = "Root disk image size in MiB";
    };

    graphics = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable QEMU graphics window (vs. serial console only)";
    };

    enableHyprland = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Keep Hyprland enabled in the VM. Requires virtio-gpu support from
        the host and will likely be sluggish. Disabled by default because
        the bare-metal config points at a specific Hyprland build from the
        flake input, which is overkill for a VM.
      '';
    };

    retainServices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "netbird" "k3s" ];
      description = ''
        Services to keep enabled in the VM even though they are disabled by
        default. The default disable-list covers services that expect physical
        hardware or the full Hyprland stack.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # ──────────────────────────────────────────────────────────
    #  virtualisation.vmVariant  —  only applied when building
    #  config.system.build.vm (or running nixos-rebuild build-vm)
    # ──────────────────────────────────────────────────────────
    virtualisation.vmVariant = {

      # ── Hardware / platform ────────────────────────────────
      # The nixos-hardware thinkpad module and Intel-specific GPU
      # config won't work in a VM.  qemu-vm.nix already pulls in
      # qemu-guest.nix which provides the virtio kernel modules.
      hardware.graphics.enable = lib.mkForce false;

      hardware.bluetooth.enable = lib.mkForce false;
      hardware.i2c.enable = lib.mkForce false;
      hardware.keyboard.qmk.enable = lib.mkForce false;

      # ── Services tied to physical hardware ─────────────────
      services.fprintd.enable = lib.mkForce false;
      services.kanata.enable = lib.mkForce false;
      services.printing.enable = lib.mkForce false;
      services.udev.extraRules = lib.mkForce "";

      # ── Boot loader overrides ──────────────────────────────
      # qemu-vm.nix uses direct boot (kernel + initrd) by default,
      # so the bootloader isn't used.  Still, grub.useOSProber
      # would waste time scanning non-existent partitions.
      boot.loader.grub.useOSProber = lib.mkForce false;
      boot.loader.grub.configurationLimit = lib.mkForce 5;

      # ── Display / compositor ───────────────────────────────
      # The base config pins a specific Hyprland flake input and
      # a custom Mesa build — neither makes sense in a QEMU VM
      # unless the user explicitly opts in via enableHyprland.
      programs.hyprland.enable = lib.mkForce cfg.enableHyprland;
      programs.hyprlock.enable = lib.mkForce cfg.enableHyprland;
      services.hypridle.enable = lib.mkForce cfg.enableHyprland;
      systemd.user.services.hyprpolkitagent.enable = lib.mkForce cfg.enableHyprland;

      # The qemu-vm.nix module already overrides xserver.videoDrivers
      # to "modesetting" with mkVMOverride (priority 10), so we don't
      # need to touch that.

      # ── Kernel ─────────────────────────────────────────────
      # Inherit linux_zen from the host config.  This will compile
      # the Zen kernel for the VM, which is fine but slow to build.
      # If you want faster VM builds, uncomment:
      #   boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;

      # ── VM resources ───────────────────────────────────────
      virtualisation.memorySize = cfg.memorySize;
      virtualisation.cores = cfg.cores;
      virtualisation.diskSize = cfg.diskSize;
      virtualisation.graphics = cfg.graphics;

      # ── Port forwarding (host:guest) ───────────────────────
      virtualisation.forwardPorts = [
        # SSH:  ssh -p 2222 jacksonb@localhost
        { from = "host"; host.port = 2222; guest.port = 22; }
      ];

      # ── Nix store sharing ──────────────────────────────────
      # By default the host Nix store is mounted read-only via 9p,
      # which is very efficient.  If you need a writable store, set
      #   virtualisation.writableStore = true;
      # or to use a dedicated disk image for the store:
      #   virtualisation.useNixStoreImage = true;

      # ── Boot ───────────────────────────────────────────────
      # For faster boot, avoid waiting for ARP on the virtual NIC.
      networking.dhcpcd.extraConfig = lib.mkForce "noarp";

      # ── State version ──────────────────────────────────────
      system.stateVersion = lib.mkDefault "24.05";
    };

    # ──────────────────────────────────────────────────────────
    #  Options exposed at the top level for convenience
    # ──────────────────────────────────────────────────────────

    # Expose a friendly build alias
    system.build.vm-fast = config.system.build.vm;
  };
}
