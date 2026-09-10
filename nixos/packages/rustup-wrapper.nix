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
      printf 'rustup-wrapper: Patching rustup binaries\n' >&2

      PATCHELF="${patchelf}/bin/patchelf"
      ZLIB="${zlib}/lib"
      EXPECTED_INTERPRETER="@expectedInterpreter@"
      JOBS="$(nproc)"

      patch_bin() {
        local f got
        f="$(readlink -f "$1")" || return 0
        got="$("$PATCHELF" --print-interpreter "$f" 2>/dev/null)" || return 0
        [[ "$got" = "$EXPECTED_INTERPRETER" ]] || "$PATCHELF" --set-interpreter "$EXPECTED_INTERPRETER" "$f"
      }

      patch_lib() {
        local f rpath new
        f="$(readlink -f "$1")" || return 0
        rpath="$("$PATCHELF" --print-rpath "$f" 2>/dev/null)" || return 0
        [[ -n "$rpath" ]] || return 0
        new="$(printf '%s\n' "$rpath" | tr ':' '\n' | sed -e '/^\/nix\/store\//d' -e '/^$/d' | tr '\n' ':')$ZLIB"
        [[ "$new" = "$rpath" ]] || "$PATCHELF" --set-rpath "$new" "$f"
      }

      export PATCHELF ZLIB EXPECTED_INTERPRETER
      export -f patch_bin patch_lib

      shopt -s nullglob
      bins=("$RUSTUP_HOME"/toolchains/*/bin/*)
      libs=("$RUSTUP_HOME"/toolchains/*/lib/*)

      if ((''${#bins[@]} + ''${#libs[@]})); then
        {
          for f in "''${bins[@]}"; do printf '%s\0%s\0' bin "$f"; done
          for f in "''${libs[@]}"; do printf '%s\0%s\0' lib "$f"; done
        } | xargs -0 -P "$JOBS" -n2 bash -euo pipefail -c 'patch_"$1" "$2"' _
      fi

      { printf '@rustupStorePath@' > "$RUSTUP_NIX_DIGEST"; } || true

      unset -f patch_bin patch_lib
      unset PATCHELF ZLIB EXPECTED_INTERPRETER
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

    # rustup's share/ is completions only so we expose it as-is
    ln -s ${rustup}/share $out/share
  ''
else
  rustup
