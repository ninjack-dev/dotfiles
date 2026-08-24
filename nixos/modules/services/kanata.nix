{
  pkgs,
  lib,
  ...
}:
# TODO: Create utility function which registers config file and tweaks systemd service
{
  services.kanata = {
    enable = true;
    package = pkgs.unstable.kanata-with-cmd;
    keyboards = {
      thinkpad.configFile = "/home/jacksonb/.config/kanata/thinkpad.kbd";
      # v10max.configFile = "/home/jacksonb/.config/kanata/v10max.kbd";
    };
  };

  # The Kanata services cannot load $HOME-bound configuration files without this. See nixpkgs #404687.
  systemd.services.kanata-thinkpad.serviceConfig = {
    ProtectHome = lib.mkForce "read-only";
    DynamicUser = lib.mkForce false;
    User = lib.mkForce "jacksonb";
  };

  # V10 max is disabled for now; needs tweaking.
  # systemd.services.kanata-v10max.serviceConfig = {
  #   ProtectHome = lib.mkForce "read-only";
  #   DynamicUser = lib.mkForce false;
  #   User = lib.mkForce "jacksonb";
  # };
}
