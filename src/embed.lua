_G.vim = neomacs

local home = os.getenv("HOME")
package.path = home .. "/.config/neomacs/lua/?.lua;" .. package.path

local neomacsPackagePath = home .. "/.local/share/neomacs/share/pkgs"
neomacs.cmd.addPackage = function(name)
    if (name == nil) then return end
    package.path = package.path ..  neomacsPackagePath .. name .. "/lua/?.lua;"
end

xpcall(function()
        loadfile(home .. '/.config/neomacs/init.lua')()
    end, function(err)
        print(tostring(err))
        print(debug.traceback(nil, 2))
        -- os.exit(1)
    end)

