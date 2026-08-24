{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:
{
  programs.zsh = {
    enable = true;
    enableGlobalCompInit = false;
  };

  environment.shellAliases = lib.mkForce { }; # Disable default `l`, `ll` aliases

  environment.sessionVariables.ZDOTDIR = "$XDG_CONFIG_HOME/zsh";
}
