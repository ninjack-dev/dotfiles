{
  lib,
  stdenv,
  fetchzip,
  makeWrapper,
  withVersion ? "261.13587.0",
}:
stdenv.mkDerivation (finalAttrs: rec {

  pname = "kotlin-lsp";
  version = "${withVersion}";
  src = fetchzip {
    url = "https://download-cdn.jetbrains.com/kotlin-lsp/${version}/kotlin-lsp-${version}-linux-x64.zip";
    hash = "sha256-EweSqy30NJuxvlJup78O+e+JOkzvUdb6DshqAy1j9jE=";
    stripRoot = false;
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/kotlin-lsp
    cp -r * $out/lib/kotlin-lsp/

    # The kotlin-lsp zip provides its own JRE, and tries to chmod it; we remove that line and do it ourselves
    sed -i '/chmod +x "$LOCAL_JRE_PATH\/bin\/java"/d' $out/lib/kotlin-lsp/kotlin-lsp.sh
    chmod +x $out/lib/kotlin-lsp/jre/bin/java

    chmod +x $out/lib/kotlin-lsp/kotlin-lsp.sh

    mkdir -p $out/bin
    makeWrapper $out/lib/kotlin-lsp/kotlin-lsp.sh $out/bin/kotlin-lsp

    runHook postInstall
  '';

  meta = {
    description = "Official Kotlin language server protocol implementation.";
    homepage = "https://github.com/Kotlin/kotlin-lsp";
    maintainers = [ "ninjack-dev" ];
    license = with lib.licenses; [ asl20 ];
    changelog = "https://github.com/Kotlin/kotlin-lsp/releases/tag/kotlin-lsp%2F${version}";
  };
})
