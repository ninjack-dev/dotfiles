{
  runCommand,
  rustup,
  stdenv,
  patchelf,
  zlib,
  writeShellScriptBin,
}:
let
  rustupWrapperScript = writeShellScriptBin "rustup" ''
    set -euo pipefail

    RUSTUP_HOME="''${RUSTUP_HOME:-$HOME/.rustup}"
    RUSTUP_NIX_DIGEST="$RUSTUP_HOME/.nix-store-path"

    if [[ -d "$RUSTUP_HOME" ]] && [[ "$(cat "$RUSTUP_NIX_DIGEST" 2>/dev/null)" != "@rustupStorePath@" ]]; then
      for f in "$RUSTUP_HOME"/toolchains/*/bin/*; do
        f="$(readlink -f "$f")" || continue
        GOT="$("${patchelf}/bin/patchelf" --print-interpreter "$f" 2>/dev/null)" || continue
        [[ "$GOT" = "@expectedInterpreter@" ]] || "${patchelf}/bin/patchelf" --set-interpreter "@expectedInterpreter@" "$f"
      done

      for f in "$RUSTUP_HOME"/toolchains/*/lib/*; do
        f="$(readlink -f "$f")" || continue
        RUNPATH="$("${patchelf}/bin/patchelf" --print-rpath "$f" 2>/dev/null)" || continue
        [[ -n "$RUNPATH" ]] || continue
        NEW="$(printf '%s\n' "$RUNPATH" | tr ':' '\n' | sed -e '/^\/nix\/store\//d' -e '/^$/d' | tr '\n' ':')${zlib}/lib"
        [[ "$NEW" = "$RUNPATH" ]] || "${patchelf}/bin/patchelf" --set-rpath "$NEW" "$f"
      done

      { printf '@rustupStorePath@' > "$RUSTUP_NIX_DIGEST"; } || true
    fi

    exec -a "$0" "${rustup}/bin/rustup" "$@"
  '';
in
# Toolchains are ELF only on Linux; elsewhere stock rustup already works.
if stdenv.hostPlatform.isLinux then
  runCommand "rustup-${rustup.version}" {
    inherit (rustup) meta version;
  } ''
    mkdir -p $out/bin
    substitute "${rustupWrapperScript}/bin/rustup" "$out/bin/rustup" \
      --subst-var-by rustupStorePath "$out" \
      --subst-var-by expectedInterpreter "$(cat ${stdenv.cc}/nix-support/dynamic-linker)"
    chmod +x $out/bin/rustup

    for p in ${rustup}/bin/*; do
      [[ -L "$p" ]] || continue
      ln -s $out/bin/rustup "$out/bin/$(basename "$p")"
    done
  ''
else
  rustup