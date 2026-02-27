local M = {}

local t = require("tbl")

local function pattern(pat)
    return "'\\v" .. pat .. "'"
end
M._cmd_args_handler = {
    start = pattern,
    skip = pattern,
    ["end"] = pattern,
}
local filter = function(key)
    return t.default(t.id)(M._cmd_args_handler[key])
end
function M._build_cmd_args(opts)
    local args = {}
    for k,v in pairs(opts) do
        local arg = k .. (function()
            local val_type = type(v)
            if val_type == "table" then
                return "=" .. filter(k)(table.concat(v,","))
            elseif val_type == "string" then
                return "=" .. filter(k)(v)
            elseif val_type == "boolean" then
                if v then
                    return k
                end
            end
        end)()
        table.insert(args,arg)
    end
    return args
end

M._sub_cmd_handler = {
    keyword = t.flip(t.curry()(table.concat))(" "),
    match = pattern,
    region = function() end,
}

function M._build_cmd(higroup) return function(opts)
    local opts_keys = vim.tbl_keys(opts)
    local sub_cmd_keys = vim.tbl_keys(M._sub_cmd_handler)
    local command = t.match(function(x)
        return vim.list_contains(sub_cmd_keys,x)
    end)(opts_keys)
    local cmd_first = { command, higroup, M._sub_cmd_handler[command](opts[command]) }
    local cmd_opts = M._build_cmd_args(t.remove(command)(opts))
    return vim.list_extend(cmd_first,cmd_opts)
end end

function M.syntax(higroup) return function(opts)
    vim.cmd.syntax(M._build_cmd(higroup)(opts))
end end

function M.link(higroup1) return function(higroup2)
    vim.api.nvim_set_hl(0,higroup1,{ link = hiroup2 })
end end

return M
