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

  environment.systemPackages = [
    unstable.atuin
    unstable.tree-sitter
    unstable.oh-my-posh

    gcc
    gnumake
    gdb

    traceroute
  ];

  fonts = {
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      noto-fonts
    ];
    enableDefaultPackages = true;
  };

  environment.sessionVariables = {
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";

    PATH = [
      "$HOME/.npm-global/bin"
      "$XDG_DATA_HOME/pnpm/bin"
      "$HOME/.deno/bin"
      "$HOME/go/bin"
      "$HOME/.cargo/bin"
    ];

    EDITOR = "nvim";
    ZDOTDIR = "$XDG_CONFIG_HOME/zsh";

    POWERSHELL_UPDATECHECK = "Off"; # Disable PowerShell's update notification; is this worth making a PR for?
  };
}
