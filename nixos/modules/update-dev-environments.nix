{
  pkgs,
  ...
}:
{

  imports = [
    ../nixosModules/update-dev-environments.nix
  ];

  # WIP; waiting to figure out API shape
  updateDevEnvironments = {
    # I use Nushell via cargo binstall
    # TODO: Check if this actually works i.e. does it have ~/.cargo/bin in PATH
    package = pkgs.writeShellScript "nushell-from-env" ''
      command -v nu &>/dev/null && exec nu 
      exec ${pkgs.unstable.nushell}/bin/nu
    '';
  };
}
