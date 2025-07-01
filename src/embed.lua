_G.vim = neomacs

local home = os.getenv("HOME")
package.path = home .. "/.config/neomacs/lua/?.lua;" .. package.path

vim.opt.packpath = home .. "/.local/share/neomacs/pkgs"
vim.cmd.portage = function(name)
    local name = name or "lazy"
    vim.print(name)
    package.path = package.path .. vim.opt.packpath .. name .. "/lua/?.lua;"
end

xpcall(function()
    loadfile(home .. '/.config/neomacs/init.lua')()
end, function(err)
    print(tostring(err))
    print(debug.traceback(nil, 2))
end)
