local M = {}

local tbl = require("tbl")

function M.from(base) return function(int_tbl)
    local function sum(i,n)
        if not int_tbl[i] then
            return n
        end
        return sum(i + 1,(n * base) + int_tbl[i])
    end
    return sum(1,0)
end end

function M.to(base) return function(int)
    local int_tbl = {}
    local function loop(n)
        if n >= base then
            table.insert(int_tbl,n % base)
            return loop(math.floor(n / base))
        else
            table.insert(int_tbl,n)
        end
    end
    loop(int)
    return tbl.reverse(int_tbl)
end end

function M.align(len) return function(list)
    local new_list = tbl.map(tbl.const(0))(tbl.range(1)(len - #list))
    return vim.list_extend(new_list,list)
end end

return M
