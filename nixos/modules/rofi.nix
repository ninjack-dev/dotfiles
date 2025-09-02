{
  lib,
  fetchFromGitHub,
  rofi-unwrapped,
  wayland-scanner,
  pkg-config,
  wayland-protocols,
  wayland,
}:

rofi-unwrapped.overrideAttrs (oldAttrs: rec {
  pname = "rofi-unwrapped";
  version = "2.0.0";

  src = fetchFromGitHub {
    owner = "davatorium";
    repo = "rofi";
    rev = version;
    fetchSubmodules = true;
    hash = "sha256-akKwIYH9OoCh4ZE/bxKPCppxXsUhplvfRjSGsdthFk4=";
  };

  depsBuildBuild = oldAttrs.depsBuildBuild ++ [ pkg-config ];
  nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
    wayland-protocols
    wayland-scanner
  ];
  buildInputs = oldAttrs.buildInputs ++ [
    wayland
    wayland-protocols
  ];

  meta = with lib; {
    description = "Window switcher, run dialog and dmenu replacement for Wayland";
    homepage = "https://github.com/davatorium/rofi";
    license = licenses.mit;
    mainProgram = "rofi";
    maintainers = with maintainers; [ ninjack-dev ];
    platforms = with platforms; linux;
  };
})
