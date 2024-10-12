-- _G.vim = neomacs

print("hello world", vim)

vim.opt.relativenumber = true
vim.opt.scrolloff = 8

-- use one of the global command provided by neomacs

local cmd = neomacs.cmd

cmd.tester = function()
    vim.notify("print from tester")
end

package.path = "/home/focus/dev/neomacs/share/lua/?.lua;" .. package.path

-- cmd.w()
-- cmd.help()

neomacs.print(cmd)

local helper = require("helper")
helper.main()

require("config.options")

