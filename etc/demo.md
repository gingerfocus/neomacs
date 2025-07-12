# Here is some broken Code
```nix
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
        # shellHook = ''
        #   export ZIG_CACHE_DIR = "./.zig-cache";
        #   export PATH="$PATH:${pkgs.zig}/bin"
        #   export PATH="$PATH:${pkgs.luajit}/bin"
```

## Some more text
With a cool image
![neon](neon.svg)

try running this code
```python
print("Hello World")
```

and this code
```zig
const std = @import("std");

pub fn main() void {
    std.debug.warn("Hello World\n");
}
```
