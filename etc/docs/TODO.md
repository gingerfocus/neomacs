# Known Bugs
- [ ] visual rendering for non-range selections is wrong

# For 0.1.2
- [X] Motions W/E/B + a/i
- [x] Undo
- [ ] Test Suite
- [ ] Fix t/f motions getting stuck
- [ ] Build on Windows + MacOS
- [ ] Update to newest zig

# For 0.2.0
- [ ] Lua API
  - [ ] Window Split
  - [ ] Make an example plugin
    - [ ] Oil/Netrw/Dired/Neotree alternative
    - [ ] Packager
- [ ] R mode
- [ ] Events and auto-comamnds
- [ ] Native Fennel Support
  
# Improvments
- [ ] a/i commands for any delimiter

# Refactors
- [x] move repeat structure to buffer
- [ ] make log better 
  - [ ] use builtin stacktrace 
  - [x] dynamically choose backend
- [ ] event loop (wait for zig async)
- [ ] remove command line??
- [ ] remove row and col from Buffer (move to curosr object)
  - [ ] remove calls to feild names in other files
- [ ] reuse motion keys map (dont call initMotionKeys on most submaps)
- [ ] remove xkb dependency for wayland

# Later
- [x] Wayland Keyrepeat
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

# Much Later
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

# Mission Features
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
