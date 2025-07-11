# Neomacs
![Neomacs Banner Logo](./etc/neon.svg)

A combination of many small projects I have worked on.

Overall, this project aims to be everything but a web browser but at least a
replacement for vim (and maybe the terminal you run it in).

# User Installation
```sh
git clone https://github.com/gingerfocus/neomacs
cd neomacs
zig build install --prefix ~/.local --release=safe
```

## Why
Neovim is great but does too many things for vim compatability. I want to see
how many features I can strip and still have a functional editor. I also kinda
want to see how extensible I can make it by allowing more complex rendering
from plugins.

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
By default, compile to a static, 740k binary with:
```sh
zig build --release=small
```


## All features
You can also build a fully capable editor by saying what you can informing what
you can link to.
```bash
zig build -Dgtk=true -Dstatic-lua=false --release=safe
```

