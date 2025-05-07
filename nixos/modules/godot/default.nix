let
  pkgs = import <nixpkgs> { };
in
pkgs.callPackage ./godot-mono.nix { }
