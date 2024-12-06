{
stdenv,
lib,
fetchurl,
autoPatchelfHook,
dotnetCorePackages,
wayland,
unzip,
makeWrapper,
udev,
libdecor,
libGL,
libpulseaudio,
libX11,
libXcursor,
libXext,
libXfixes,
libXi,
libXinerama,
libxkbcommon,
libXrandr,
libXrender,
fontconfig,
alsa-lib,
vulkan-loader,
    dbus
}:

stdenv.mkDerivation (finalAttrs: rec {
  pname = "godot4-dotnet";
  version = "4.3";

  src = fetchurl {
    url = "https://github.com/godotengine/godot/releases/download/${version}-stable/Godot_v4.3-stable_mono_linux_x86_64.zip";
    hash = "sha256-7N881aYASmVowZlYHVi6aFqZBZJuUWd5BrdvvdnK01E=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    unzip
    makeWrapper
  ];

  buildInputs = [
    dotnetCorePackages.dotnet_8.sdk
    wayland
    libX11
    libGL
    udev
    libdecor
    libGL
    libpulseaudio
    libX11
    libXcursor
    libXext
    libXfixes
    libXi
    libXinerama
    libxkbcommon
    libXrandr
    libXrender
    dbus
    dbus.lib
    fontconfig
    alsa-lib
    libGL
    vulkan-loader
  ];

  libraries = lib.makeLibraryPath buildInputs;

  source-root = ".";

  unpackCmd = "unzip $curSrc -d .";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -m755 Godot_v${version}-stable_mono_linux.x86_64 $out/bin/godot
    mv GodotSharp $out/bin
    
    runHook postInstall
  '';

postFixup = ''
    wrapProgram $out/bin/godot \
      --set LD_LIBRARY_PATH ${libraries}
  '';

  meta = {
    description = "";
    homepage = "";
  };
})
