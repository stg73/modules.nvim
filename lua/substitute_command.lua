local M = {}

function M.get_command(tbl)
    return function(range)
        local substitute = require("regex").gsub(function(x) return tbl[x] end)(".")
        local current_lines = vim.api.nvim_buf_get_lines(0,range[1] - 1,range[2],false)
        local new_lines = require("tbl").map(substitute)(current_lines)
        vim.api.nvim_buf_set_lines(0,range[1] - 1,range[2],false,new_lines)
    end
end

function M.create_command(name) return function(tbl)
    vim.api.nvim_create_user_command(name,function(opts)
        M.get_command(tbl)({ opts.line1, opts.line2 })
    end,{ range = true, bar = true })
end end

return M
