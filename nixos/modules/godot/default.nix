let
  pkgs = import <unstable> { };
in
pkgs.callPackage ./godot-mono.nix { }
