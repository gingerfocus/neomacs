local rt = require("runtime")

_G.vim = vim
_G.neon = neon

if neon then
    print("neon loaded")
    rt.compat()
end

print("hello neomacs")

vim.opt.relativenumber = true
vim.opt.autoindent = true
vim.opt.scrolloff = 8

vim.cmd.NeonTex = function()
    vim.cmd.w()
    vim.notify("neon tex")
end

vim.print(neon.opt.scrolloff)

vim.cmd.Test = function()
    vim.notify("Running make")

    vim.loop:exec("make", {
        after = function(code, signal)
            vim.notify("make done with code " .. code .. " and signal " .. signal)
        end,
    })
end

-- local stat = vim.loop.stat("/bin/sh")
-- if not not stat then
--     vim.print("file is " .. tostring(stat.size) .. " bytes")
--     vim.print(stat)
-- end

-- vim.keymap.set("n", "<leader>t", ":Test<CR>")

-- vim.print(neon.cmd)
-- for k, v in pairs(vim.cmd) do
--     vim.print(k, v)
-- end

-- cool example of shimming the editor function to write a file with a template
local edit = vim.cmd.e
vim.cmd.e = function(file)
    file = file or "tmp"
    -- vim.loop.stat(file, function(err, stat) end)
    local stat = vim.loop.stat(file)
    if not stat then
        vim.loop:write(file, "template file\n", {
            after = function()
                edit(file)
            end,
        })
    else 
        edit(file)
    end
end
