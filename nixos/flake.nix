{
  description = "System flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland.url = "github:hyprwm/Hyprland?ref=v0.56.2";
  };

  outputs =
    {
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
            { ... }:
            {
              nix = {
                channel.enable = false;
                registry = {
                  nixpkgs.flake = nixpkgs;
                  unstable.flake = nixpkgs-unstable;
                };
              };

              nixpkgs.overlays = [
                overlay-stable
                overlay-unstable
              ];

              environment.etc."nix/inputs/nixpkgs".source = nixpkgs.outPath;
              environment.etc."nix/inputs/unstable".source = nixpkgs-unstable.outPath;

              nix.nixPath = [
                "nixpkgs=/etc/nix/inputs/nixpkgs"
                "unstable=/etc/nix/inputs/unstable"
              ];

              nix.settings = {
                substituters = [ "https://hyprland.cachix.org" ];
                trusted-substituters = [ "https://hyprland.cachix.org" ];
                trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
              };
            }
          )
          ./modules/configuration.nix
          nixos-hardware.nixosModules.lenovo-thinkpad-e14-intel-gen6
        ];
      };
    };
}
