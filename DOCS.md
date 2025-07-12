# Dev Log
## Previewing Ui
```bash
zig build run -- -R tmp.txt <file>
```

## Input / Command Line
I think I should really start to think about architechture for this as it seems
really flimsy at this point. Maybe just use a single threaded event loop (xev)
and rewrite it at some point.

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

I also want to have typst integration which can be an external dependency which
raises the question of how to render it and i think supporting mupdf or poppler
may be interesting or again use it through a lua binding.

## Complex Rendering
I am toying with the idea of shaders and for that I would need sampling which
would require images which would require heavy data throughput for lua. I think
it is good to get ahead of this problem by creating an api that is just like a
memmap where you can make an fd to write to which will be drawn to the screen.
Most libraries should have a binding for this so the data never needs to pass
through lua.

## Wasm
No, I dont think so.

## Async
I dont want to go all in on xev only for the new zig IO model to come out and
be stuck.
