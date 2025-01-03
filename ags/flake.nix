{
  description = "Full AGS v2 Installation";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    ags = {
      url = "github:aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ags,
    }: let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages.${system}.default = 
        pkgs.buildEnv { 
          name = "ags"; 
          paths = with pkgs; builtins.attrValues (
            # This grabs all Astal packages from the AGS flake. Might be a more efficient way of doing it.
            builtins.removeAttrs ags.packages.${system} ["default" "ags" "docs" ] 
          ) ++ [
              fzf
              adwaita-icon-theme
              # (ags.packages.${system}.agsFull.override {
              #   extraPackages = with pkgs; [
                  # Extra packages for AGS runtime here
                # ];
              # })
            ];
        }; 
    };
}


# Dev shell in case I decide to remove AGS/Astall binaries from PATH. Unlikely
# devShells.${system} = {
#   default = pkgs.mkShell {
#
#     packages = [ 
#       ags.packages.${system}.agsFull
#     ];
#
#     buildInputs = [
#       ags.packages.${system}.agsFull
#       pkgs.adwaita-icon-theme
#
#       (ags.packages.${system}.default.override {
#         extraPackages = [
#
#         ];
#       })
#     ];
#   };
# };

#       # Packages listed here for later convenience
#       # ags.packages.${system}.io
#       # ags.packages.${system}.astal3 
#       # ags.packages.${system}.astal4
#       # ags.packages.${system}.apps 
#       # ags.packages.${system}.auth
#       # ags.packages.${system}.battery 
#       # ags.packages.${system}.bluetooth 
#       # ags.packages.${system}.cava # This is broken for now. 
#       # ags.packages.${system}.greet 
#       # ags.packages.${system}.hyprland 
#       # ags.packages.${system}.mpris 
#       # ags.packages.${system}.network 
#       # ags.packages.${system}.notifd 
#       # ags.packages.${system}.powerprofiles 
#       # ags.packages.${system}.river 
#       # ags.packages.${system}.tray 
#       # ags.packages.${system}.wireplumber 
