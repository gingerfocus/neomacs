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

pub const lua_rawgeti = c.lua_rawgeti;
pub const luaL_newstate = c.luaL_newstate;
pub const luaL_loadstring = c.luaL_loadstring;
pub const lua_close = c.lua_close;

pub const LUA_REGISTRYINDEX = c.LUA_REGISTRYINDEX;

pub const luaL_openlibs = c.luaL_openlibs;
pub const lua_pcall = c.lua_pcall;

pub const luaL_ref = c.luaL_ref;
pub const luaL_unref = c.luaL_unref;

pub const lua_newtable = c.lua_newtable;

pub const lua_pushnil = c.lua_pushnil;
pub const lua_pushboolean = c.lua_pushboolean;
pub const lua_pushnumber = c.lua_pushnumber;
pub const lua_pushinteger = c.lua_pushinteger;
pub const lua_pushlstring = c.lua_pushlstring;
pub const lua_pushstring = c.lua_pushstring;
// pub const lua_pushlightuserdata = c.lua_pushlightuserdata;
pub const lua_pushcfunction = c.lua_pushcfunction;
pub const lua_pushvalue = c.lua_pushvalue;

pub const lua_setglobal = c.lua_setglobal;
pub const lua_getglobal = c.lua_getglobal;

pub const lua_setfield = c.lua_setfield;
pub const lua_getfield = c.lua_getfield;

pub const lua_setmetatable = c.lua_setmetatable;

pub const lua_toboolean = c.lua_toboolean;
pub const lua_touserdata = c.lua_touserdata;
pub const lua_tointeger = c.lua_tointeger;
pub const lua_tonumber = c.lua_tonumber;
pub const lua_tostring = c.lua_tostring;
pub const lua_tolstring = c.lua_tolstring;
pub const lua_tocfunction = c.lua_tocfunction;

pub const lua_isnil = c.lua_isnil;
// pub const lua_islightuserdata = c.lua_islightuserdata;
pub const lua_isfunction = c.lua_isfunction;
pub const lua_istable = c.lua_istable;
pub const lua_isboolean = c.lua_isboolean;
pub const lua_isstring = c.lua_isstring;
pub const lua_isnumber = c.lua_isnumber;

pub const lua_gettop = c.lua_gettop;
pub const lua_pop = c.lua_pop;

pub const LUA_MULTRET = c.LUA_MULTRET;

pub const LUA_TNONE = c.LUA_TNONE;
pub const LUA_TNIL = c.LUA_TNIL;
pub const LUA_TBOOLEAN = c.LUA_TBOOLEAN;
pub const LUA_TLIGHTUSERDATA = c.LUA_TLIGHTUSERDATA;
pub const LUA_TNUMBER = c.LUA_TNUMBER;
pub const LUA_TSTRING = c.LUA_TSTRING;
pub const LUA_TTABLE = c.LUA_TTABLE;
pub const LUA_TFUNCTION = c.LUA_TFUNCTION;

pub const lua_next = c.lua_next;
pub const lua_type = c.lua_type;

pub const lua_error = c.lua_error;
pub const lua_typename = c.lua_typename;
