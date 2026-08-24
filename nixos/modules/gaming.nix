{
  pkgs,
  ...
}:
{
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
