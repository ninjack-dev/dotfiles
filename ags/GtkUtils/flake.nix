
{  
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs, ... }@inputs: 
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.${system} = {
        default = pkgs.mkShell {
          packages = [ 
            pkgs.gobject-introspection
            pkgs.gjs
            pkgs.gtk3
          ];
        };
      };

    };

}


