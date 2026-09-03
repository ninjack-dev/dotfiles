{
  pkgs,
  ...
}:
{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
    "pipe-operators"
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  programs.nix-ld = {
    enable = true;
    libraries =
      with pkgs;
      [ fuse ]
      ++ (pkgs.appimageTools.defaultFhsEnvArgs.targetPkgs pkgs)
      ++ (pkgs.appimageTools.defaultFhsEnvArgs.multiPkgs pkgs);
  };

  programs.command-not-found.enable = false;
  programs.nix-index.enable = true;

  environment.systemPackages = with pkgs; [
    nurl
    hydra-check
  ];
}
