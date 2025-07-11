local M = {}

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

-- Only run once by the embedded lua startup code
M.startup = function()
    print("neon runtime loaded")

    local home = os.getenv("HOME")
    xpcall(function()
        if not neon.loop.stat(home .. "/.config/neomacs/init.lua") then
            print("neon: init.lua not found")
            print("writing default init.lua")
            -- TODO: do it
            -- vim.opt.runtime .. "init.lua"
            return
        end

        loadfile(home .. "/.config/neomacs/init.lua")()
    end, function(err)
        print(tostring(err))
        -- print(debug.traceback(nil, 2))
    end)

    neon.cmd.portage = M.portage

    -- package.path = neon.opt.runtime .. "/lua/?.lua;" .. package.path
end

M.setup = function(opts)
    _ = opts
end

-- TODO: make this something more formal
-- Could be better as a neon.compat function not runtime.compat
M.compat = function()
    _G.vim = neon

    neon.cmd.w = neon.buf.write
    neon.cmd.q = neon.api.quit
    neon.cmd.wq = function()
        neon.buf.write()
        neon.api.quit()
    end
    neon.cmd.e = neon.buf.edit
    neon.cmd.bn = neon.buffer.next
    neon.cmd.bp = neon.buffer.prev
end

return M
