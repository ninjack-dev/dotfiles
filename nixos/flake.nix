{
  description = "System flake.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    hyprland.url = "github:hyprwm/Hyprland?ref=v0.53.1";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      nixos-hardware,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      overlay-unstable = final: prev: {
        unstable = import nixpkgs-unstable {
          inherit system;
          config = {
            allowUnfree = true;
            # TODO: Research how interactions with overlays works. Is this the only way to customize unstable?
            # Waiting on #3224 (in Ventoy) for blobs to be built from scratch, at which point this should be marked as secure again
            permittedInsecurePackages = [
              "${nixpkgs-unstable.legacyPackages.${system}.ventoy.name}"
            ];
          };
        };
      };
      overlay-stable = final: prev: {
        stable = nixpkgs.legacyPackages.${prev.system};
      };
    in
    {
      nixosConfigurations."nixos-laptop" = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs nixpkgs nixpkgs-unstable; };
        modules = [
          (
            { config, pkgs, ... }:
            {
              nix = {
                channel.enable = false;
                registry = {
                  nixpkgs.flake = nixpkgs;
                  nixpkgs-unstable.flake = nixpkgs-unstable;
                  nixos-hardware.flake = nixos-hardware;
                };
              };

              nixpkgs.overlays = [
                overlay-stable
                overlay-unstable
              ];

              nix.nixPath = [
                "nixpkgs=${nixpkgs.outPath}"
                "unstable=${nixpkgs-unstable.outPath}"
              ];

              nix.settings = {
                substituters = [ "https://hyprland.cachix.org" ];
                trusted-substituters = [ "https://hyprland.cachix.org" ];
                trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
              };
            }
          )
          ./configuration.nix
          nixos-hardware.nixosModules.lenovo-thinkpad-e14-intel-gen6
        ];
      };
    };
}
