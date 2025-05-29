{ lib, stdenv, callPackage, zig }:
stdenv.mkDerivation {
    pname = "zss";
    version = "0.1.0";

    src = ./..;

    nativeBuildInputs = [ zig.hook ];

    buildInputs = [];

    zigBuildFlags = [ "--system" "${ callPackage ./neomacs-zig-zon.nix { } }" "zss" ];
}
