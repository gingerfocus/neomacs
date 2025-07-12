{
  inputs.nixpkgs.url = "nixpkgs-unstable"; # "nixpkgs";
  inputs.zig.url = "github:mitchellh/zig-overlay/6f9a3c160daca2a701a638a7ea7b0e675c1a1848";
  inputs.zig.inputs.nixpkgs.follows = "nixpkgs";

  outputs = {
    self,
    nixpkgs,
    zig,
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

        packages = [
          pkgs.valgrind
          pkgs.strace
          pkgs.zon2nix

          pkgs.scdoc
          pkgs.freetype
          pkgs.atk

          pkgs.gtk3
          pkgs.cairo
          pkgs.gobject-introspection
          # pkgs.skia

          pkgs.python3
          pkgs.pyright
          pkgs.bearssl

          pkgs.luajit

          pkgs.pkg-config
          pkgs.wayland
          pkgs.wayland-scanner
          pkgs.wayland-protocols
          pkgs.libxkbcommon

          # Development
          pkgs.alejandra
          pkgs.stylua
          pkgs.lua-language-server

          # zig.packages."${system}".master
          pkgs.zig
        ];

        # shellHook = ''
        #   export ZIG_CACHE_DIR = "./.zig-cache";
        #   export PATH="$PATH:${pkgs.zig}/bin"
        #   export PATH="$PATH:${pkgs.luajit}/bin"
        #   export PATH="$PATH:${pkgs.python3}/bin"
        # '';
      };

      formatter = pkgs.alejandra;

      packages = {
        default = neon.neomacs;
        neomacs = pkgs.callPackage ./nix/neomacs.nix {};
        zss = pkgs.callPackage ./nix/zss.nix {};
      };
    });
}
