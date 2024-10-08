{ lib, stdenv, zig, luajit, tree-sitter, tree-sitter-grammars }:
stdenv.mkDerivation {
    hardeningDisable = [ "format" "fortify" ];

    pname = "neomacs";
    version = "0.0.1";

    src = ./.;

    nativeBuildInputs = [zig];
    buildInputs = [
      luajit
      (luajit.withPackages (ps: (with ps; [ fennel ])))

      tree-sitter
      tree-sitter-grammars.tree-sitter-zig
    ];

    buildPhase = ''
      ${zig}/bin/zig build --prefix $out                \
            --cache-dir /build/zig-cache                \
            --global-cache-dir /build/global-cache      \
            -Doptimize=ReleaseFast
    '';
}
