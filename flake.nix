{
  inputs.nixpkgs.url = "nixpkgs-unstable"; # "nixpkgs";

  outputs = {
    self,
    nixpkgs,
    # graphi,
  }: let
    lib = nixpkgs.lib;
    systems = ["aarch64-linux" "x86_64-linux"];
    eachSystem = f:
      lib.foldAttrs lib.mergeAttrs {}
      (map (s: lib.mapAttrs (_: v: {${s} = v;}) (f s)) systems);
  in
    eachSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          # (final: prev: {graphi = graphi.packages.${system}.default;})
        ];
      };
      neon = self.packages."${system}";
    in {
      devShells.default = pkgs.mkShell {
        # inputsFrom = with neon; [neomacs zss];

        packages = with pkgs; [
          valgrind
          strace
          zon2nix

          scdoc
          freetype
          atk

          gtk3
          cairo
          gobject-introspection
          #skia

          python3
          pyright

          zig
          luajit
          pkg-config
          wayland
          wayland-scanner
          wayland-protocols
          libxkbcommon
        ];
      };

      formatter = pkgs.alejandra;

      packages = {
        default = neon.neomacs;
        neomacs = pkgs.callPackage ./nix/neomacs.nix {};
        zss = pkgs.callPackage ./nix/zss.nix {};
      };
    });
}
