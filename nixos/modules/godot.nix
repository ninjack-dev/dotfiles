{
stdenv,
# lib,
fetchurl,
autoPatchelfHook,
dotnet-sdk_8,
wayland,
unzip,
libX11,
libGL
}:

stdenv.mkDerivation (finalAttrs: rec {
  pname = "godot4-dotnet";
  version = "4.3";

  src = fetchurl {
    url = "https://github.com/godotengine/godot/releases/download/${version}-stable/Godot_v4.3-stable_mono_linux_x86_64.zip";
    hash = "";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    unzip
  ];

  buildInputs = [
    dotnet-sdk_8
    wayland
    libX11
    libGL
  ];

  source-root = ".";

  unpackCmd = "unzip $curSrc -d source";

  installPhase = ''
    runHook preInstall
    install -m755 -D Godot_v${version}-stable_mono_linux.x86_64 $out/bin/godot
    runHook postInstall
  '';

  meta = {
    description = "";
    homepage = "";
  };
})
