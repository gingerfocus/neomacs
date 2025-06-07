{
  lib,
  stdenv,
  zig,
  pkg-config,
  wayland,
  wayland-scanner,
  wayland-protocols,
  libxkbcommon,
}:
stdenv.mkDerivation {
  pname = "wev";
  version = "1.0.0";

  src = ./.;

  buildInputs = [
    pkg-config
    wayland
    wayland-scanner
    wayland-protocols
    libxkbcommon
  ];

  # nativeBuildInputs = [ zig.hook ];
  # zigBuildFlags = [ "--system" "${ callPackage ./neomacs-zig-zon.nix { } }" "wev" ];

  nativeBuildInputs = [zig];
  buildPhase = "${zig}/bin/zig build --prefix $out --cache-dir /build/zig-cache --global-cache-dir /build/global-cache -Doptimize=ReleaseSafe wev";
}
