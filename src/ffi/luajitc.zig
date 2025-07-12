//! This file is used by the build system to provide a module for the luacode when compiling
//! the luajit C API into a shared library.
//!

const c = @cImport({
    @cInclude("lua.h");
    @cInclude("lualib.h");
    @cInclude("luajit.h");
    @cInclude("luajit-2.1/lauxlib.h");
});

pub const lua_State = c.lua_State;

