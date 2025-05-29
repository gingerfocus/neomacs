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
        # cp config/* ~/.config/neomacs/
        devShells.default = pkgs.mkShell {
          inputsFrom = with neon; [
            # TODO: i want to use the packages but not the zig hook
            # neomacs
            wev
            # foot
            # surf
            # neovide
          ];

          WAYLAND_PROTOCOLS = pkgs.wayland-protocols;

          packages = with pkgs; [ 
            valgrind
            strace
            zon2nix

            luajit
            (luajit.withPackages (ps: (with ps; [ fennel ])))

            tree-sitter
            tree-sitter-grammars.tree-sitter-zig
          ];
        };

        formatter = pkgs.alejandra;
        # formatter = pkgs.nixfmt-classic;

        packages = {
          default = neon.neomacs;
          neomacs = pkgs.callPackage ./nix/neomacs.nix { };
          zss = pkgs.callPackage ./nix/zss.nix { };
          wev = pkgs.callPackage ./sub/wev/wev.nix { };
          # foot = pkgs.callPackage ../sub/foot/foot.nix { };
          # neovide = pkgs.callPackage ../sub/neovide/neovide.nix {};
        };
      });
}
