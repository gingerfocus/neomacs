{
  inputs.nixpkgs.url = "nixpkgs";

  outputs = { self, nixpkgs, }:
    let
      hardeningDisable = [ "format" "fortify" ];
      lib = nixpkgs.lib;
      systems = [ "aarch64-linux" "x86_64-linux" ];
      eachSystem = f:
        lib.foldAttrs lib.mergeAttrs { }
        (map (s: lib.mapAttrs (_: v: { ${s} = v; }) (f s)) systems);
      # forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in eachSystem (system:
      let 
      pkgs = import nixpkgs { inherit system; };
      neon = self.packages."${system}";
      in {
        devShells.default = pkgs.mkShell {
          inherit hardeningDisable;

          inputsFrom = with neon; [
            neomacs
            wev
          ];

          packages = with pkgs; [ valgrind ];
        };

        # formatter.${system} = pkgs.alejandra;

        packages = {
          default = neon.neomacs;
          wev = pkgs.callPackage ./sub/wev/wev.nix {};
          neomacs = pkgs.stdenv.mkDerivation {
            inherit hardeningDisable;

            name = "neomacs";
            src = ./.;

            buildInputs = with pkgs; [
              tree-sitter
              tree-sitter-grammars.tree-sitter-zig
            ];

            buildPhase =
              "${pkgs.zig}/bin/zig build --prefix $out --cache-dir /build/zig-cache --global-cache-dir /build/global-cache -Doptimize=ReleaseFast";
          };
        };
      });
}
