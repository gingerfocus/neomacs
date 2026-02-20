# Neon
![Neon Banner Logo](./etc/branding/logo.jpg)

Everything but a web browser.

# Installation
```sh
git clone --depth 1 https://github.com/gingerfocus/neomacs.git
cd neomacs
zig build install --prefix ~/.local --release=safe
```

Nixos users can use the following:
```sh
nix build github:gingerfocus/neomacs
```

Static terminal compilation:
```sh
zig build -Dstatic=true -Dwayland=false --release=small
```

# Development
see [TODO.md](./etc/docs/TODO.md) for random ideas I have.

## Tests
run all tests:
```bash
zig build test --summary all
```

## Lines of Code
I want to limit the scope of this project. I have a hard cap of 10k lines of
code and am currently at ~8500. This means I will likely have to do a great
refactor or descoping soon.

Lua code does not count.

## Why
I want to easily allow for complex rendering for plugins. In addition, by
keeping the scope of the project low I think I can make a powerful editor.
