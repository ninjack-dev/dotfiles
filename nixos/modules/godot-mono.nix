# Example of patched binary - https://github.com/NixOS/nixpkgs/blob/nixos-24.11/pkgs/by-name/ob/obsidian/package.nix#L19
# Godot_4-mono - https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/development/tools/godot/common.nix
# MUST BE BUILT WITH UNSTABLE FOR NOW
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
  libxkbcommon,
  xorg,
  speechd-minimal,
  fontconfig,
  alsa-lib,
  imagemagick,
  vulkan-loader,
  dbus,
  withVersion ? "4.5.1-stable",
}:

stdenv.mkDerivation (finalAttrs: rec {
  pname = "godot-mono";
  version = "${withVersion}";

  src = fetchurl {
    url = "https://github.com/godotengine/godot/releases/download/${version}/Godot_v${version}_mono_linux_x86_64.zip";
    hash = "sha256-thaX3Wkh2nbj0jWKtZImPfquOY0KwSKeguq35KfDbL8=";
  };

  icon = fetchurl {
    name = "godot-icon";
    url = "https://raw.githubusercontent.com/godotengine/godot/refs/tags/${version}/icon.svg";
    hash = "sha256-FEOul0hCuBdl1bUOanKeu/Qeui6eUVqwkZ8upci49HU=";
  };

  desktopItem = fetchurl {
    name = "godot-desktop-file"; # The filename is invalid for the nix store, apparently; when this is not set, it downloads the raw HTML of the webpage...
    url = "https://raw.githubusercontent.com/godotengine/godot/refs/tags/${version}/misc/dist/linux/org.godotengine.Godot.desktop";
    hash = "sha256-z+T3b7utkNQ+cCfX+WNxaef//kpGIfGAJOBX0u4s0pw=";
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

    cp ${desktopItem} $out/share/applications/godot.desktop

    cp ${icon} $out/share/icons/scalable

      for size in 16 24 32 48 64 128 256 512; do
        mkdir -p $out/share/icons/hicolor/"$size"x"$size"/apps
        magick -background none ${icon} -resize "$size"x"$size" $out/share/icons/hicolor/"$size"x"$size"/apps/godot.png
      done

    runHook postInstall
  '';

  libraries = lib.makeLibraryPath buildInputs;

  # DOTNET_SYSTEM_GLOBALIZATION_INVARIANT is a temporary fix while waiting for libicu fix
  postInstall = ''
    wrapProgram $out/bin/godot \
      --set "DOTNET_SYSTEM_GLOBALIZATION_INVARIANT" 1 \
      --set LD_LIBRARY_PATH ${libraries} \
      --set DOTNET_ROOT "${dotnetCorePackages.sdk_9_0_1xx}" \
      --prefix PATH : ${lib.makeBinPath [ dotnetCorePackages.sdk_9_0_1xx ]} \
      --add-flags "--display-driver wayland"
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
