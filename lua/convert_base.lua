local M = {}

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
            loop(math.floor(n / base))
        else
            table.insert(int_tbl,n)
        end
    end
    loop(int)

    return vim.fn.reverse(int_tbl)
end end

function M.align(len) return function(int_tbl)
    local list = {}
    local list_len = len - #int_tbl
    local function loop(i)
        if i < list_len then
            table.insert(list,0)
            loop(i + 1)
        end
    end
    loop(0)

    return vim.list_extend(list,int_tbl)
end end

return M
