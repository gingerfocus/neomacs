{ lib, stdenv, callPackage, zig }:
stdenv.mkDerivation {
    pname = "zss";
    version = "0.1.0";

    src = ./..;

    buildInputs = [];

    # nativeBuildInputs = [ zig.hook ];
    # zigBuildFlags = [ "--system" "${ callPackage ./neomacs-zig-zon.nix { } }" "zss" ];

    nativeBuildInputs = [zig];
    buildPhase = "${zig}/bin/zig build --prefix $out --cache-dir /build/zig-cache --global-cache-dir /build/global-cache -Doptimize=ReleaseSafe wev";
}
