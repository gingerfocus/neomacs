# known bugs
- [ ] key press while pressing shift releasing shift and releasing key causes
      it to repeat forever as it is not being reset

# For 0.1.1
- [x] Basic Targeters (w/e/b, t/f, $/0)
- [x] Deletion (d/x/D)
- [x] Changing (c/C)
- [x] Replace (r)
- [x] Yank (y)
- [ ] Visual Mode Targeting (Right, Line, Block)
- [ ] Scroll off

# For 0.2.0
- [ ] Window Split
- [ ] More motions
  - [ ] W/E/B
- [ ] Lua API
- [ ] Undo
- [ ] Make an example plugin
  - [ ] Oil/Netrw/Dired/Neotree alternative
- [ ] More Motions ('a', 'i') "(){}[]"
- [ ] R mode

# Refactors
- [ ] move repeat structure to buffer
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
- [ ] Packager
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

# Much Later
- [ ] Inline Image preview
- [ ] Shader support
  - [ ] Shaders from Lua
- [ ] Pdf support
  - [ ] Typst support
- [ ] RPC
- [ ] C/Wasi Api
- [ ] Literate Programming
- [ ] TigerStyle type fuzzing
  - [ ] Compared to Neovim
- [ ] file co-operation
- [ ] Static compile Wayland+Wgpu backend

https://typst.app/universe/package/timeliney
