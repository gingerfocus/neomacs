# Neomacs
![Neomacs Banner Logo](./etc/neon.svg)

A combination of many small projects I have worked on

Overall, this project aims to be everything but a web browser. And you should
(eventually) be able to run a system with only busybox, this, ssh and firefox
installed.

## Why
Neovim is great but does too many things for vim compatability. I want to see
how many features I can strip and still have a functional editor.

## Commands
Commands are very different from vim but are designed to feel like they "just
work" all the same. First, all commands are written in lua, not vim script. But
it is still easy to shorthand some of your most used commands. If you just type
a word, that function will be looked up and called, this lets you type things
like `w` or `tutor`. Any more complicated command will just be parsed as
straight lua meaning that there is no second syntax to learn and you can type
`os.exit(1)` right into the command line if you wanted.

# Devolopment
## All features
Build toolchain is capabell of linking in many different things with default
build.
```bash
zig build -Doptimize=ReleaseFast
```

## Binary Size
Can be compiled to a static 740k binary with:
```bash
zig build -Dwindows=false -Dstatic=true -Doptimize=ReleaseSmall
```

# Dev Log
## Keybinds
I think I should modify the current system to use a chording thing were each
new press is just a pointer dereference to a new key map. Also, I think it
would be cool if key maps optionally returned a target so the yank delete and
replace motions could be generalized to user defined motions. If a target is
returned to the root then it moves there. I think this would be a very small
breaking change for some obscure keys but a net good for things. Although first
I should just implement the basics.
