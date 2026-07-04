let
  pkgs = import <unstable> {};
in
final: prev: (pkgs.callPackage ./packages.nix { })
