local M = {}

function M.filter(fn) return function(arg_tbl)
    local t = {}
    for _,v in pairs(arg_tbl) do
        if fn(v) then
            table.insert(t,v)
        end
    end
    return t
end end

M.find = function(pred) return function(tbl)
    for k,v in pairs(tbl) do
        if pred(v) then
            return v
        end
    end
    return nil
end end

function M.map(fn) return function(arg_tbl)
    local t = {}
    for k,v in pairs(arg_tbl) do
        t[k] = fn(v)
    end
    return t
end end

function M.pairs(fn) return function(arg_tbl)
    local t = {}
    for k,v in pairs(arg_tbl) do
        local key_val = fn({k,v})
        if key_val then
            t[key_val[1]] = key_val[2]
        end
    end
    return t
end end

-- テーブルからキーの値を取得する M.pipe({{"hoge","fuga"},M.get(1)}) == "hoge"
function M.get(key) return function(tbl)
    return tbl[key]
end end

function M.flip(fn) return function(x) return function(y)
    return fn(y)(x)
end end end

M.fix2 = function(f)
    local function fixed(...)
        return f(fixed,...)
    end
    return fixed
end

local function fix(f)
    return f(function(x)
        return fix(f)(x)
    end)
end
M.fix = fix

M.fold = function(fn) return function(init) return function(list)
    return M.fix2(function(loop,acc,i)
        if list[i] == nil then
            return acc
        else
            return loop(fn(acc,list[i]),i + 1)
        end
    end)(init,1)
end end end

M.fold1 = function(fn) return function(list)
    return M.fix2(function(loop,acc,i)
        if list[i] == nil then
            return acc
        else
            return loop(fn(acc,list[i]),i + 1)
        end
    end)(list[1],2)
end end

-- 関数合成
local function compose(f1,f2)
    return function(x)
        return f1(f2(x))
    end
end
M.compose = M.fold1(compose)

M.pipe = M.fold1(function(v,f)
    return f(v)
end)

local copy_table = function(tbl)
    local new_tbl = {}
    for k,v in pairs(tbl) do
        new_tbl[k] = v
    end
    return new_tbl
end

function M.curry(n) return function(fn)
    n = n or 2
    return M.fix2(function(loop,args,len,actual_len)
        if len >= n then
            return fn(unpack(args,1,actual_len))
        else
            return function(...)
                local _args = copy_table(args)
                for _,v in pairs({...}) do
                    table.insert(_args,v)
                end
                local _actual_len = select("#",...)
                local _len = (_actual_len == 0) and 1 or _actual_len
                return loop(_args,len + _len,actual_len + _actual_len)
            end
        end
    end)({},0,0)
end end

M.uncurry = function(fn) return function(...)
    local args = {...}
    local len = select("#",...)
    return M.fix2(function(loop,fn,i)
        local retv = fn(args[i])
        if i >= len then
            return retv
        else
            return loop(retv,i + 1)
        end
    end)(fn,1)
end end

M.range = function(list)
    local start = list[1]
    local dist,finish
    if list[3] then
        finish = list[3]
        dist = list[2] - start
    else
        finish = list[2]
        if start <= finish then
            dist = 1
        else
            dist = -1
        end
    end
    local not_last = function(n)
        if dist > 0 then
            return n <= finish
        else
            return n >= finish
        end
    end
    local new_list = {}
    M.fix2(function(loop,i)
        if not_last(i) then
            table.insert(new_list,i)
            return loop(i + dist)
        end
    end)(start)
    return new_list
end

M.replicate = function(n) return function(x)
    local new_list = {}
    M.fix2(function(loop,i)
        if i >= 1 then
            table.insert(new_list,x)
            return loop(i - 1)
        end
    end)(n)
    return new_list
end end

function M.chunks(size) return function(tbl)
    local t = {}
    local finish = #tbl
    M.fix2(function(loop,i)
        if i <= finish then
            local sub_idx = math.ceil(i / size)
            t[sub_idx] = t[sub_idx] or {}
            table.insert(t[sub_idx],tbl[i])
            return loop(i + 1)
        end
    end)(1)
    return t
end end

function M.append(x) return function(list)
    local new_list = copy_table(list)
    table.insert(new_list,x)
    return new_list
end end

function M.prepend(x) return function(list)
    local new_list = { x }
    vim.list_extend(new_list,list)
    return new_list
end end

function M.insert(k) return function(v) return function(tbl)
    local new_tbl = copy_table(tbl)
    new_tbl[k] = v
    return new_tbl
end end end

M.remove = M.flip(M.insert)()

M.flatten = function(depth) return function(list)
    depth = depth or 1
    local new_list = {}
    M.fix2(function(flatten,depth,list)
        for _,v in pairs(list) do
            if (type(v) == "table") and (depth >= 1) then
                flatten(depth - 1,v)
            else
                table.insert(new_list,v)
            end
        end
    end)(depth,list)
    return new_list
end end

M.reverse = function(list)
    local new_list = {}
    M.fix2(function(loop,i)
        if i >= 1 then
            table.insert(new_list,list[i])
            return loop(i - 1)
        end
    end)(#list)
    return new_list
end

M.transpose = function(list)
    local len = #list
    local new_list = {}
    M.fix2(function(loop,i)
        local tuple = M.map(M.get(i))(list)
        if #tuple == len then
            table.insert(new_list,tuple)
            return loop(i + 1)
        end
    end)(1)
    return new_list
end

M.id = function(x)
    return x
end

M.const = function(x) return function(_)
    return x
end end

M.default = function(default) return function(x)
    if x == nil then
        return default
    else
        return x
    end
end end

return M
