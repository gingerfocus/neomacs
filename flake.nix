{
  inputs.nixpkgs.url = "nixpkgs";

  outputs = { self, nixpkgs, }:
    let
      lib = nixpkgs.lib;
      systems = [ "aarch64-linux" "x86_64-linux" ];
      eachSystem = f:
        lib.foldAttrs lib.mergeAttrs { }
        (map (s: lib.mapAttrs (_: v: { ${s} = v; }) (f s)) systems);
    in eachSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        neon = self.packages."${system}";
      in {
        devShells.default = pkgs.mkShell {
          inputsFrom = with neon; [ 
            neomacs 
            wev 
            # surf 
          ];

          packages = with pkgs; [ 
            valgrind
            strace
            zon2nix
          ];
        };

        # formatter = pkgs.alejandra;
        # formatter = pkgs.nixfmt-classic;

        packages = {
          default = neon.neomacs;
          wev = pkgs.callPackage ./sub/wev/wev.nix { };
          # surf = pkgs.callPackage ./sub/surf/surf.nix { };
          neomacs = pkgs.callPackage ./neomacs.nix { };
        };
      });
}
