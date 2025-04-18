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
      # As nice as using `nix fmt` would be, for now, it doesn't make much sense to use, as it's really a flake only feature. 
      # If I have any generic .nix file anywhere in my system, I can either `nix fmt <relative path>` while in `.config/nixos`,
      # or I can run `nix run <path to flake dir>#formatter.x86_64-linux <file>`, which is immensely tedious. 
      # Best to just use nixfmt via nixpkgs.
      # formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
      nixosConfigurations."nixos-laptop" = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          (
            { config, pkgs, ... }:
            {
              nix = {
                registry = {
                  nixpkgs.flake = nixpkgs;
                  nixos-hardware.flake = nixos-hardware;
                };
              };

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
