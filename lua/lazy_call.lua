local M = {}

local t = require("tbl")

function M.lazy(opt) return function(callback)
    -- 特定のキーが押されたらloadする
    local function load_map(mode) return function(map)
        vim.keymap.set(mode,map,function()
            vim.keymap.del(mode,map)
            callback()
            return map
        end,{ expr = true, desc = opt.desc })
    end end

    if opt.event then
        vim.api.nvim_create_autocmd(opt.event,{
            pattern = opt.pattern,
            callback = callback,
            once = true,
            desc = opt.desc,
        })
    end
    if opt.keys then
        t.map(function(tuple)
            if type(tuple[2]) == "table" then
                t.map(load_map(tuple[1]))(tuple[2])
            else
                load_map(tuple[1])(tuple[2])
            end
        end)(opt.keys)
    end
    if opt.command then
        vim.api.nvim_create_user_command(opt.command,function(opts)
            vim.api.nvim_del_user_command(opt.command)
            callback()
            local command_exists = vim.api.nvim_get_commands({})[opt.command]
            if command_exists then
                vim.cmd({ cmd = opt.command, args = opts.fargs })
            end
        end,{ nargs = "*", desc = opt.desc })
    end
end end

return M
