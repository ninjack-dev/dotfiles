# Example of patched binary
# https://github.com/NixOS/nixpkgs/blob/nixos-24.11/pkgs/by-name/ob/obsidian/package.nix#L19
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
  xorg,
  libXrender,
  speechd-minimal,
  fontconfig,
  alsa-lib,
  imagemagick,
  vulkan-loader,
  dbus,
  withVersion ? "4.4.1-stable",
}:

stdenv.mkDerivation (finalAttrs: rec {
  pname = "godot-mono";
  version = "${withVersion}";

  src = fetchurl {
    url = "https://github.com/godotengine/godot/releases/download/${version}/Godot_v${version}_mono_linux_x86_64.zip";
    hash = "sha256-uV5pTKGD63IDdmRc3DVHcVzG0MAhUoI4y2UZmCriiy8=";
  };

  icon = fetchurl {
    url = "https://raw.githubusercontent.com/godotengine/godot/refs/heads/master/icon.svg";
    hash = "sha256-FEOul0hCuBdl1bUOanKeu/Qeui6eUVqwkZ8upci49HU=";
  };

  desktopItem = fetchurl {
    url = "https://raw.githubusercontent.com/godotengine/godot/refs/heads/master/misc/dist/linux/org.godotengine.Godot.desktop";
    hash = "sha256-ujzuI5ghekPy2aNvCMPrBo9Dc9gXS4XdEuTb+B8SM/8=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    unzip
    imagemagick
    makeWrapper
  ];

  buildInputs = [
    alsa-lib
    libGL
    vulkan-loader
    xorg.libX11
    xorg.libXcursor
    xorg.libXext
    xorg.libXfixes
    xorg.libXi
    xorg.libXinerama
    libxkbcommon
    xorg.libXrandr
    xorg.libXrender
    libdecor
    wayland
    dbus
    dbus.lib
    fontconfig
    fontconfig.lib
    libpulseaudio
    speechd-minimal
    udev
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    mkdir -p $out/share/{applications,icons/hicolor/scalable/apps}
    install -m755 Godot_v${version}_mono_linux.x86_64 $out/bin/godot
    mv GodotSharp $out/bin
    install -m 444 ${desktopItem} $out/share/applications/godot-${version}.desktop

      for size in 16 24 32 48 64 128 256 512; do
        mkdir -p $out/share/icons/hicolor/"$size"x"$size"/apps
        magick -background none ${icon} -resize "$size"x"$size" $out/share/icons/hicolor/"$size"x"$size"/apps/godot.png
      done

    runHook postInstall
  '';

  libraries = lib.makeLibraryPath buildInputs;

  postInstall = ''
    wrapProgram $out/bin/godot \
      --set LD_LIBRARY_PATH ${libraries} \
      --set DOTNET_ROOT "${dotnetCorePackages.sdk_9_0_1xx}" \
      --prefix PATH : ${lib.makeBinPath [ dotnetCorePackages.sdk_9_0_1xx ]}
  '';

  meta = {
    changelog = "https://github.com/godotengine/godot/releases/tag/${version}";
    description = "Free and Open Source 2D and 3D game engine";
    homepage = "https://godotengine.org";
    license = lib.licenses.mit;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    maintainers = with lib.maintainers; [
      NinjacksonXV
    ];
    mainProgram = "godot4-mono";
  };
})
