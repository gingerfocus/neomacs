# Neomacs
![Neomacs Banner Logo](./etc/neon.svg)

A combination of many small projects I have worked on.

Overall, this project aims to be everything but a web browser and at least a
replacement for vim (and maybe the terminal you run it in).

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
By default, build a capable editor linking to as much as the build system can
given your os configuration.
```bash
zig build -Doptimize=ReleaseFast
```

## Binary Size
Compile to a static, 740k binary with:
```bash
zig build -Dwindowing=false -Dstatic=true -Doptimize=ReleaseSmall
```

# Dev Log
## Previewing Ui
```bash
zig build run -- --dosnapshot tmp.txt <file>
```

## Keybinds
Key binds are chorded meaning that each key either does something or places you
in a submap/mode. Some of these modes are very small but its fine. It may be a
breaking change for some obscure keys but is a net good for things.

**Modeless**
I dont think there needs to be a list mode modes anywhere, each key func can
just be responsible for changing the mode and have them all arena allocated (or
use arcs).

**Tree Mode**
I have not implemented buffer local key binding but i think it could be cool to have a tree 
with all the key bindings and when you locally change it for one buffer you clone that node of the tree 
to add to it.

This raises more problems than it may solve as now I have to make a version managment sytem
for keybinds just to save some memory sometimes

## Libraries
It may be worth it to just use gtk for rendering. Also I think long term using
[libghostty](https://github.com/ghostty-org/ghostty) for the terminal would be a good idea but I should at least finish
the product first before working on that.


