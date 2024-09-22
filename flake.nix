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
      let pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          inherit hardeningDisable;

          inputsFrom = [self.packages.${system}.zano];
          packages = with pkgs; [ gcc valgrind ncurses ];
        };

        # formatter.${system} = pkgs.alejandra;

        packages = {
          default = self.packages.${system}.zano;
          zano = pkgs.stdenv.mkDerivation {
            inherit hardeningDisable;

            name = "zano";
            src = ./.;

            buildInputs = [ pkgs.ncurses ];

            buildPhase =
              "${pkgs.zig}/bin/zig build --prefix $out --cache-dir /build/zig-cache --global-cache-dir /build/global-cache -Doptimize=ReleaseFast";
          };
        };
      });
}
