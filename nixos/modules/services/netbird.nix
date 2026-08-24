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
    "${inputs.nixpkgs-unstable}/nixos/modules/services/networking/netbird.nix"
  ];

  services.netbird = {
    clients.default = {
      port = 51820;
      name = "netbird";
      interface = "wt0";
      config = {
        IFaceBlackList = [
          "cni0"
          "flannel.1"
          "wt0"
          "wt"
          "utun"
          "tun0"
          "zt"
          "ZeroTier"
          "wg"
          "ts"
          "Tailscale"
          "tailscale"
          "docker"
          "veth"
          "br-"
          "lo"
        ]; # Ignore misc. virtual ifaces, otherwise NetBird ICE tries to punch through which fails
      };
      hardened = false;
    };
    package = pkgs.unstable.netbird;
    ui.package = pkgs.unstable.netbird-ui;
  };
}
