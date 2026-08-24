{
  pkgs,
  lib,
  config,
  ...
}:
# WIP. The goal is to allow a user to provide Nushell snippets which can update tool config files with store paths,
# e.g. a `pyproject.toml` file in a Kitty config directory. The API shape is still undetermined.
let
  cfg = config.updateDevEnvironments;
in
with lib;
{
  options.updateDevEnvironments.package = mkPackageOption pkgs "nushell" { };
}
