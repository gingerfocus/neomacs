# Neomacs
![Neomacs Banner Logo](./etc/branding/logo.jpg)

Overall, this project aims to be everything but a web browser but at least a
replacement for vim (and maybe the terminal you run it in).

Combinines many small projects I have worked on:
- **shade**: a reference shader visualizer for wgsl
- **graphi**: graphics library
- **luma**: idea managment software
- **vfoot**: [!] a modified version of foot that can be embedded
- **surf**: [!] an embeddable browser to bridge compatability for old websites
- **zimv**: [!] image viewer
- **imvr**: [!] image viewer

Other projects:
- Take inspiration from [orca](https://github.com/orca-app/orca).
- Uses some templating from [jot](https://github.com/shashwatah/jot).

# User Installation
```sh
git clone https://github.com/gingerfocus/neomacs
cd neomacs
zig build install --prefix ~/.local --release=safe
```

Nixos users can use the following:
```sh
nix build github:gingerfocus/neomacs
```

## Why
Neovim is great but does too many things for vim compatability. By breaking
compatability with certain core features but maintaining the main data flow I
think I can cut the maintence base of code by lots.

Emacs is great but does too many things.

I also kinda allow complex rendering for plugins for both.

## Commands
Commands are very different from vim but are designed to feel like they "just
work" all the same. First, all commands are written in lua, not vim script. But
it is still easy to shorthand some of your most used commands. If you just type
a word, that function will be looked up and called, this lets you type things
like `w` or `tutor`. Any more complicated command will just be parsed as
straight lua meaning that there is no second syntax to learn and you can type
`os.exit(1)` right into the command line if you wanted.

# Devolopment
## Binary Size
Recomended compilation is to a static, 780k binary with:
```sh
zig build -Dstatic=true -Dwayland=false --release=small
```

## Windowing
You can also install a fully capable editor by using the recomeneded flags:
```bash
zig build install --release=safe --prefix ~/.local -Dwayland=true
```

## Progress
see [TODO.md](./etc/docs/TODO.md) for random ideas I have.

## Lines of Code
I very much dont like maintaining code so I just dont write it. I am hard
limiting myself to 10k lines of zig code (currently 4493). More lua code can be
written but to me all lua code can be replaced at runtime so it is not
premanent.
