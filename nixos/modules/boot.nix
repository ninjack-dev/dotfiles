{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:
{
  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_zen;
    kernel = {
      sysctl."kernel.sysrq" = 1;
    };
    loader = {
      efi.canTouchEfiVariables = true;
      grub.enable = true;
      grub.device = "nodev";
      grub.efiSupport = true;
      grub.useOSProber = true;
      grub.configurationLimit = 30;
    };
    tmp.cleanOnBoot = true;

  };
}
