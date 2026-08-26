{
  pkgs,
  ...
}:
# Override devenv so it reports /run/current-system/sw/bin/bash as the
# login shell instead of whatever getpwuid() finds. This is a hack to fix
# the fact that non-Bash shells are searched for there before falling back
# to $SHELL or the PATH, which messes with my Kitty wrappers. Upstream needs
# to be fixed at some point.
#
# Caveats: a constructor in the override unsets LD_PRELOAD once loaded, so
# devenv's children don't inherit the hack. Side effect: any other preloads
# the env had are dropped for those children too. Nobody here relies on those.
let
  devenv =
    let
      orig = pkgs.unstable.devenv;
      shellOverride = pkgs.runCommandCC "getpwuid-override" { } ''
        mkdir -p "$out"
        cc -O2 -Wall -shared -fPIC -o "$out/getpwuid-override.so" ${./getpwuid-override.c} -ldl
      '';
    in
    pkgs.runCommand "devenv-shell-override"
      {
        pname = "devenv";
        inherit (orig) meta;

        dontFixup = true;

        nativeBuildInputs = [ pkgs.makeWrapper ];
      }
      ''
        set -e

        mkdir -p "$out"
        # Not sure about this, LLM slop
        for entry in "${orig}"/*; do
          name="$(basename "$entry")"
          [ "$name" = bin ] && continue
          ln -s "$entry" "$out/$name"
        done

        mkdir -p "$out/bin"
        for entry in "${orig}"/bin/* "${orig}"/bin/.[!.]*; do
          name="$(basename "$entry")"
          [ "$name" = devenv ] && continue
          ln -s "$entry" "$out/bin/$name"
        done

        mkdir -p "$out/lib"
        ln -s "${shellOverride}/getpwuid-override.so" "$out/lib/getpwuid-override.so"

        makeWrapper "${orig}/bin/devenv" "$out/bin/devenv" \
          --prefix LD_PRELOAD ":" "$out/lib/getpwuid-override.so"
      '';
in
{
  # TODO: Consider sticking this in an overlay
  environment.systemPackages = [ devenv ];
}
