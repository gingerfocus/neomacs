{
  lib,
  stdenv,
  callPackage,
  zig,
  luajit,
  tree-sitter,
  tree-sitter-grammars,
  pkg-config,
  wayland,
  wayland-scanner,
  wayland-protocols,
  libxkbcommon,
  # graphi,
}:
stdenv.mkDerivation {
  pname = "neomacs";
  version = "0.1.0";

  src = ./..;

  buildInputs = [
    luajit
    (luajit.withPackages (ps: (with ps; [fennel])))

    tree-sitter
    tree-sitter-grammars.tree-sitter-zig

    pkg-config
    wayland
    wayland-scanner
    wayland-protocols
    libxkbcommon

    # graphi

    # libuv
  ];

  # nativeBuildInputs = [zig.hook];
  # zigBuildFlags = ["--system" "${callPackage ./neomacs-zig-zon.nix {}}"];

  nativeBuildInputs = [ zig ];
  buildPhase = "${zig}/bin/zig build --prefix $out --cache-dir /build/zig-cache --global-cache-dir /build/global-cache -Doptimize=ReleaseSafe";
}
