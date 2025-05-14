-- _G.vim = neomacs

print("hello neomacs")

vim.opt.relativenumber = true
vim.opt.autoindent = false
vim.opt.scrolloff = 8

neomacs.cmd.NeonTex = function()
    neomacs.cmd.w()
    vim.notify("neon tex")
end

-- print("hello world")
--
-- neomacs.print(neomacs.opt)
--
-- neomacs.print(neomacs.opt.scrolloff)
--
-- vim.opt.relativenumber = true
-- vim.opt.autoindent = false
-- vim.opt.scrolloff = 8
--
-- neomacs.print(neomacs.opt)
--
-- -- use one of the global command provided by neomacs
-- local cmd = neomacs.cmd
--
-- cmd.tester = function()
--     vim.notify("print from tester")
-- end
--
-- cmd.w()
--
-- package.path = "/home/focus/dev/neomacs/share/lua/?.lua;" .. package.path
--
-- local helper = require("helper")
-- helper.main()
--
-- require("config.options")



-- vim.opt.autoindent = false
-- print("hello from the inner file")

-- local M = {}
--
-- M.main = function()
--     print("required object function call")
-- end
--
-- return M
