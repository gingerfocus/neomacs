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
  gtk3,
  cairo,
  gobject-introspection,
  freetype,
  atk,
  glfw
}:
stdenv.mkDerivation {
  pname = "neomacs";
  version = "0.1.0";

  src = ./..;

  buildInputs = [
    ## Basic Dependencies
    luajit # we can statically build this, not strictly necessary, the headers are nice
    # (luajit.withPackages (ps: (with ps; [fennel])))

    ## Gtk Dependencies
    gtk3
    cairo
    gobject-introspection

    ## Wayland Dependencies
    pkg-config
    wayland
    wayland-scanner
    wayland-protocols
    libxkbcommon
    freetype
    atk

    # Gpu Dependencies
    glfw

    # tree-sitter
    # tree-sitter-grammars.tree-sitter-zig
  ];

  nativeBuildInputs = [zig.hook];
  zigBuildFlags = ["--system" "${callPackage ./neomacs-zig-zon.nix {}}" "-Dstatic=false"];
}
