{
  lib,
  stdenv,
  fetchzip,
  makeWrapper,
  zulu24,
  jdk ? zulu24,
  withVersion ? "0.253.10629",
}:
stdenv.mkDerivation (finalAttrs: rec {

  pname = "kotlin-lsp";
  version = "${withVersion}";
  src = fetchzip {
    url = "https://download-cdn.jetbrains.com/kotlin-lsp/${version}/kotlin-${version}.zip";
    hash = "sha256-LCLGo3Q8/4TYI7z50UdXAbtPNgzFYtmUY/kzo2JCln0=";
    stripRoot = false;
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/kotlin-lsp
    cp -r * $out/lib/kotlin-lsp/

    chmod +x $out/lib/kotlin-lsp/kotlin-lsp.sh

    mkdir -p $out/bin
    makeWrapper $out/lib/kotlin-lsp/kotlin-lsp.sh $out/bin/kotlin-lsp \
      --prefix PATH : ${jdk}/bin

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
