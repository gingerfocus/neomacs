{
  # inputs.nixpkgs.url = "nixpkgs";
  inputs.nixpkgs.url = github:nixos/nixpkgs/b3582c75c7f21ce0b429898980eddbbf05c68e55;

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
            neomacs
            wev
            zss
            # graphi
            # foot
            # surf
          ];

          WAYLAND_PROTOCOLS = pkgs.wayland-protocols;

          packages = with pkgs; [ 
            # valgrind
            # strace
            zon2nix

            # luajit
            # (luajit.withPackages (ps: (with ps; [ fennel ])))

            # tree-sitter
            # tree-sitter-grammars.tree-sitter-zig

            # zig
            # zig_0_13
            zls
            # bun
          ];
        };

        formatter = pkgs.alejandra;
        # formatter = pkgs.nixfmt-classic;

        packages = {
          default = neon.neomacs;
          neomacs = pkgs.callPackage ./nix/neomacs.nix { };
          zss = pkgs.callPackage ./nix/zss.nix { };
          wev = pkgs.callPackage ./nix/wev.nix { };
          # foot = pkgs.callPackage ./sub/foot/foot.nix { };
        };
      });
}
