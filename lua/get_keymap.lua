local M = {}

function M.get(mode,lhs,opts)
    local opts = opts or {}
    local keymap_table = (function()
        if opts.buffer then
            return vim.api.nvim_buf_get_keymap(opts.buffer,mode)
        else
            return vim.api.nvim_get_keymap(mode)
        end
    end)()

    if keymap_table == nil then
        return nil
    end

    local keymap = require("tbl").find(function(t) return t.lhs == lhs end)(keymap_table)

    if opts.remap then
        return M.get(mode,keymap.rhs,{ buffer = opts.buffer })
    end

    return keymap
end

return M
