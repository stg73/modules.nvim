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

-- テーブルから条件に適合するものを検索する
function M.match(pre) return function(tbl)
    local function loop(i)
        local arg = tbl[i]
        if arg == nil then
            return nil
        elseif pre(arg) then
            return arg
        else
            return loop(i + 1)
        end
    end
    return loop(1)
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

-- シェルのパイプのように関数を繋げていく
function M.pipe(tbl)
    local function loop(fn_idx,arg)
        if tbl[fn_idx] == nil then
            return arg
        end
        return loop(fn_idx + 1,tbl[fn_idx](arg))
    end
    return loop(2,tbl[1])
end

-- テーブルからキーの値を取得する M.pipe({{"hoge","fuga"},M.get(1)}) == "hoge"
function M.get(key) return function(tbl)
    return tbl[key]
end end

function M.flip(fn) return function(x) return function(y)
    return fn(y)(x)
end end end

function M.fold(fn) return function(tbl)
    local function loop(result,i)
        if tbl[i] == nil then
            return result
        else
            return loop(fn(result,tbl[i]),i + 1)
        end
    end
    return loop(tbl[1],2)
end end

-- 関数合成
local function compose(f1,f2)
    return function(x)
        return f1(f2(x))
    end
end
M.compose = M.fold(compose)

function M.curry(n) return function(fn)
    n = n or 2
    local function loop(args)
        if #args >= n then
            return fn(unpack(args))
        else
            return function(arg)
                return loop(M.append(arg)(args))
            end
        end
    end
    return loop({})
end end

function M.range(s) return function(e)
    local t = {}
    local function loop(i)
        if i <= e then
            table.insert(t,i)
            return loop(i + 1)
        else
            return t
        end
    end
    return loop(s)
end end

function M.chunks(size) return function(tbl)
    local t = {}
    local function loop(i)
        if i <= #tbl then
            local sub_idx = math.ceil(i / size)
            t[sub_idx] = t[sub_idx] or {}
            table.insert(t[sub_idx],tbl[i])
            return loop(i + 1)
        end
    end
    loop(1)
    return t
end end

local copy_table = function(tbl)
    local new_tbl = {}
    for k,v in pairs(tbl) do
        new_tbl[k] = v
    end
    return new_tbl
end

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
