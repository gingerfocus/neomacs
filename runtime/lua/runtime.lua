local M = {}

local neon = _G.neon

M.portage = function(name)
    -- standard package management
    if not name then
        return
    end
    -- TODO: install it
    -- I think it would be cool to provide some very nice primitives for networking
    -- and just let package management be a consequence of that so if someone wants
    -- to make their own they get the same near native speed.
    neon.print(name)
    -- neon.loop.exec("git clone https://github.com/" .. name .. ".git")
    package.path = package.path .. neon.opt.packpath .. name .. "/lua/?.lua;"
end

--- Ran by the embedded startup script, you can call this again at your own risk
M.startup = function()
    print("neon runtime loaded")

    local home = os.getenv("HOME")
    xpcall(function()
        -- neon.loop.stat(home .. "/.config/neomacs/init.lua")
        local init = loadfile(home .. "/.config/neomacs/init.lua")

        if not init then
            print("neon: init.lua not found, using default")
            -- print("writing default init.lua")

            init = loadfile(vim.opt.runtime .. "/init.lua") or function() end
        end

        init()
    end, function(err)
        print(tostring(err))
        -- print(debug.traceback(nil, 2))
    end)
end

---@class rt.SetupOpts
---@field portage boolean enable the builtin in package management system

---@param opts? rt.SetupOpts
M.setup = function(opts)
    ---@type rt.SetupOpts
    local defaults = {
        portage = true,
    }
    opts = opts or defaults

    if opts.portage then
        neon.cmd.portage = M.portage
    end
end

-- TODO: make this something more formal
-- Could be better as a neon.compat function not runtime.compat
M.compat = function()
    print("doing best effort vim api emulation")

    _G.vim = neon

    neon.cmd.w = neon.buf.write
    neon.cmd.q = neon.api.quit
    neon.cmd.wq = function()
        neon.buf.write()
        neon.api.quit()
    end
    neon.cmd.e = neon.buf.edit
    neon.cmd.bn = neon.buf.next
    neon.cmd.bp = neon.buf.prev
end

-- HACK: this is just for testing beacuse im bad
M.compat()

return M
