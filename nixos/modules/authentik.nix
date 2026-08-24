{
  ...
}:
{
  imports = [
    ../nixosModules/authentik-platform.nix
  ];

  nixpkgs.overlays = [
    (final: prev: prev.lib.callPackageWith prev ../packages/authentik-platform.nix { })
  ];

  # TODO: Re-enable when necessary (build is difficult ATM)
  # services.authentik-platform = {
  #   enable = true;
  #   agent.enable = true;
  # };
}
