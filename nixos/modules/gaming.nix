{
  pkgs,
  inputs,
  ...
}:
{

  disabledModules = [
    "programs/steam.nix"
  ];

  imports = [
    "${inputs.unstable}/nixos/modules/programs/steam.nix"
  ];

  programs.gamescope = {
    enable = true;
    package = pkgs.unstable.gamescope;
    capSysNice = false;
    args = [
      "--expose-wayland"
    ];
  };

  programs.steam = {
    enable = true;
    package = pkgs.unstable.steam;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    gamescopeSession.enable = true;
    extraPackages = with pkgs; [
      coreutils # Needed for Gamescope session
    ];
  };
}
