{ lib, stdenv, callPackage, zig, luajit, tree-sitter, tree-sitter-grammars }:
stdenv.mkDerivation {
    pname = "neomacs";
    version = "0.1.0";

    src = ./..;

    nativeBuildInputs = [ zig.hook ];

    buildInputs = [
      luajit
      (luajit.withPackages (ps: (with ps; [ fennel ])))

      tree-sitter
      tree-sitter-grammars.tree-sitter-zig

      libuv
    ];

    zigBuildFlags = [ "--system" "${ callPackage ./neomacs-zig-zon.nix { } }" ];
}
