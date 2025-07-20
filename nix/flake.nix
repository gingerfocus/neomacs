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
          (final: prev: {
            # zig = zig.packages."${system}".master;
            # graphi = graphi.packages.${system}.default;
          })
        ];
      };
      neon = self.packages."${system}";
    in {
      devShells.default = pkgs.mkShell {
        inputsFrom = with neon; [neomacs zss];

        packages = [
          pkgs.pkg-config
          pkgs.zon2nix

          ## Literate Programming Dependencies
          # pkgs.python3
          # pkgs.pyright

          ## Networking Dependencies
          pkgs.bearssl

          # Development
          pkgs.alejandra
          pkgs.stylua
          pkgs.lua-language-server
        ];

        # HACK: Allow for local development despite presence of zig.hook
        shellHook = ''
          export ZIG_CACHE_DIR="$PWD/.zig-cache"
          export ZIG_GLOBAL_CACHE_DIR="$HOME/.cache/zig"
          export NEONRUNTIME="$PWD/runtime"
        '';
      };

      formatter = pkgs.alejandra;

      packages = {
        default = neon.neomacs;
        neomacs = pkgs.callPackage ./neomacs.nix {};
        zss = pkgs.callPackage ./zss.nix {};
      };
    });
}
