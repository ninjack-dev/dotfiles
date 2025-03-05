{
  description = "A very basic flake to start. https://nixos.wiki/wiki/Flakes#Importing_packages_from_multiple_channels";

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
        # https://discourse.nixos.org/t/allow-unfree-in-flakes/29904/2
        # TODO: Figure out how to get the prev.system in here.
        unstable = import nixpkgs-unstable {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
      };
      overlay-stable = final: prev: {
        stable = nixpkgs.legacyPackages.${prev.system};
      };
    in
    {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
      nixosConfigurations."nixos-laptop" = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          (
            { config, pkgs, ... }:
            {
              nixpkgs.overlays = [
                overlay-stable
                overlay-unstable
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
