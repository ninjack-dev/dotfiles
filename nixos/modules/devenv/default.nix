{
  pkgs,
  ...
}:
# Override devenv so it reports /run/current-system/sw/bin/bash as the
# login shell instead of whatever getpwuid() finds. This is a hack to fix
# the fact that non-Bash shells are searched for there before falling back
# to $SHELL or the PATH, which messes with my Kitty wrappers. Upstream needs
# to be fixed at some point.
let
  overrideLib = pkgs.runCommandCC "getpwuid-override" { } ''
    mkdir -p "$out/lib"
    cc -O2 -Wall -shared -fPIC -o "$out/lib/getpwuid-override.so" ${./getpwuid-override.c} -ldl
  '';

  devenv = pkgs.symlinkJoin {
    name = "devenv-shell-override";
    paths = [ pkgs.unstable.devenv ];
    meta = devenv.meta;
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm "$out/bin/devenv"
      makeWrapper "${devenv}/bin/devenv" "$out/bin/devenv" --prefix LD_PRELOAD ":" "${overrideLib}/lib/getpwuid-override.so"
    '';
  };
in
{
  # TODO: Consider sticking this in an overlay
  environment.systemPackages = [ devenv ];
}
