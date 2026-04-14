Guide to writing code for neon.

# Commands
## Running Tests
```sh
zig build test --summary all
```

## Previewing UI
Displays a text repersentation of the first rendered frame of a given file. Can replace tmp.txt with /dev/stdout.

```sh
zig build run -- -R tmp.txt <file>
```

# Blockers
## Event Loop
There is not currently an event loop but there will be eventually. An current
feature that requires one could be implemented with xev but it is a better idea
to wait for standard library support for rather that have to rewrite it. As such
features that need an event loop should be delayed.

## Complex Rendering
It may be possible to do shaders but that would require high data thoughput for
lua. I need to build some abstraction so lua can work with the objects but the
memory never passes through its virtual machine.

# Style Guide
## File Organization
- Each module should import `root.zig` first: `const root = @import("root.zig");`
- Access std via `root.std` rather than re-importing
- Use `@This()` for struct receivers

```zig
const root = @import("root.zig");
const std = root.std;

const MyStruct = @This();
```

## Naming Conventions
- **Types**: `PascalCase`
- **Functions/Variables**: `camelCase`
- **Constants**: `PascalCase`
- **Enums**: `PascalCase`
- **Struct fields**: `camelCase`

## Module Imports
All public modules are exported from `root.zig`:
```zig
pub const Args = @import("Args.zig");
pub const Buffer = @import("Buffer.zig");
pub const km = @import("km/root.zig");
pub const lib = @import("lib/root.zig");
```

Prefer accessing them via `root.ModuleName` rather than directly import.

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

$ for f in $(find src/ -name '*.zig'); do echo "$(wc -l < $f)" "$f"; done

$ find src/ -name '*.zig' | xargs cat | wc -l
8555

## Why
I want to easily allow for complex rendering for plugins. In addition, by
keeping the scope of the project low I think I can make a powerful editor.

