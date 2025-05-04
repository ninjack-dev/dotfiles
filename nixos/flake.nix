{
  description = "System flake.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
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
          config.allowUnfree = true;
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
            }
          )
          ./configuration.nix
          # nixos-hardware.nixosModules.framework-13th-gen-intel
          # nixos-hardware.nixosModules.lenovo-thinkpad-e14-intel
        ];
      };
    };
}
