# Bugs
- [ ] Rendering for visual selections is wrong
- [ ] Many crashes...

# For 0.1.2
- [X] Motions W/E/B + a/i
- [x] Undo
- [X] Test Suite
- [X] Fix t/f motions
- [X] Implement F/T motions
- [ ] Update to Zig 0.16
- [ ] Fix Rope Crashes

# For 0.2
- [ ] Lua API
  - [ ] Window Split
  - [ ] Make an example plugin
    - [ ] Oil/Netrw/Dired/Neotree alternative
    - [ ] Packager
- [ ] Events and auto-comamnds
- [ ] Build on MacOS
- [ ] Around/Inside accept *any* delimiter
- [ ] R mode
- [ ] Native Fennel Support

# Refactors
- [ ] log with builtin stacktrace
- [ ] event loop (wait for zig async)
- [ ] remove command line??
- [ ] remove row and col from Buffer (move to curosr object)
  - [ ] remove calls to feild names in other files
- [ ] reuse motion keys map (dont call initMotionKeys on most submaps)
- [ ] remove xkb dependency for wayland

# For 1.0
- [ ] Lsp
- [ ] Swap Files
- [ ] Fix window backend sizing
- [ ] Hardware Acceleration
  - [ ] Drop gtk backend
- [ ] Batch Rendering Primitives
- [ ] Better renering of text
- [ ] Font Support
- [ ] Marks
- [ ] Vim `s` or Flash `s`?
- [ ] `z` commands
  - [ ] folds
- [ ] swaping the start and end position visual selection
- [ ] Rope Buffers / CRDT / VSR
- [ ] Multi Backend
- [ ] Total runtime configuration to make paging truely zero cost
  - [ ] rework state object to handle missing/unconfigured resources
  - [ ] remove zss.zig file, should just be a consequence of the above
- [ ] C/Wasi Api
- [ ] Shader support
  - [ ] Shaders from Lua
- [ ] Pdf support
  - [ ] Image preview
  - [ ] Typst support
- [ ] RPC
- [ ] Literate Programming
- [ ] TigerStyle type fuzzing
  - [ ] Compared to Neovim
- [ ] file co-operation
- [ ] Static compile Wayland+Wgpu backend

# Missing Features
Here I add features that are missing in this editor that are in vim. Many of
them will be marked as not planned but it think it is a good idea to have a
list. Also they can be implemented in user space.

## Command Line
- :ls (:file)
- :cd
- :b
- :find (path)

### :args
I think this is just bad, I make fun of having tabs windows and buffers but a
separate arg list is just not needed.
- `:next` & `:prev`
- `]a` & `[a`
- `:rewind` & `:last`
- `]A` & `[A`

- `:arglocal`
- `:argdo`

## Commands
- gf
- g<c-g>

