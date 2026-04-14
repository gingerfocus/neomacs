# Neon
![Neon Banner Logo](./etc/branding/logo.jpg)

Everything but a web browser.

# Installation
Main is very often broken. Please install from lastest tag.

```sh
git clone --depth 1 --branch v0.1.1 https://github.com/gingerfocus/neomacs.git
cd neomacs
zig build install --prefix ~/.local --release=safe
```

Nixos users can use the following:
```sh
nix build github:gingerfocus/neomacs/v0.1.1
```

Static terminal compilation:
```sh
zig build -Dstatic=true -Dwayland=false --release=small
```

