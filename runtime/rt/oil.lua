local M = {}

function M.load(path)
    local f = io.open(path, "r")
    if not f then
        return nil
    end
    local content = f:read("*a")
    f:close()
    return content
end

function M.setup(opts)
    -- vim.keymap.set("n", "<leader>t", ":Test<CR>")
end

return M
