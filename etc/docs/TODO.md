# Known Bugs
- [ ] visual rendering for non-range selections is wrong

# For 0.1.2
- [ ] More motions
  - [ ] W/E/B
  - [ ] a/i "(){}[]"
- [ ] Undo

# For 0.2.0
- [ ] Lua API
  - [ ] Window Split
  - [ ] Make an example plugin
    - [ ] Oil/Netrw/Dired/Neotree alternative
    - [ ] Packager
- [ ] R mode

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
- [ ] Component events (subscriptions)
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
