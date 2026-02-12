local M = {}

function M.filter(fn) return function(arg_tbl)
    local t = {}
    for i = 1, #arg_tbl do
        if fn(arg_tbl[i]) then
            table.insert(t,arg_tbl[i])
        end
    end

    return t
end end

-- pre(arg)であればfn(arg)を返す そうでなければnilを返す
function M.map_filter(fn) return function(pre) return function(arg)
    if pre(arg) then
        return fn(arg)
    else
        return nil
    end
end end end

-- テーブルから条件に適合するものを検索する
function M.match(pre) return function(tbl)
    local function f(i)
        local arg = tbl[i]
        if arg == nil then
            return nil
        elseif pre(arg) then
            return arg
        else
            return f(i + 1)
        end
    end

    return f(1)
end end

function M.map(fn) return function(arg_tbl)
    local t = {}
    for i = 1, #arg_tbl do
        local retval = fn(arg_tbl[i])
        table.insert(t,retval)
    end

    return t
end end

function M.foreach(fn) return function(arg_tbl)
    local keys = vim.tbl_keys(arg_tbl)
    M.map(function(key)
        fn(key)(arg_tbl[key])
    end)(keys)
end end

function M.map_map(fn) return function(arg_tbl)
    local t = {}
    M.foreach(function(key) return function(val)
        t[key] = fn(val)
    end end)(arg_tbl)
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

-- M.mapの 関数と引数が逆
function M.map_reverse(fn_tbl) return function(arg)
    local t = {}
    for i = 1, #fn_tbl do
        table.insert(t,(fn_tbl[i])(arg))
    end

    return t
end end

-- シェルのパイプのように関数を繋げていく
function M.pipe(tbl)
    local function f(i,arg)
        if tbl[i] == nil then
            return arg
        end
        return f(i + 1,tbl[i](arg))
    end

    return f(2,tbl[1])
end

-- 関数合成
function M.compose(tbl)
    local function f(i,fn)
        if tbl[i] == nil then
            return fn
        else
            return f(i + 1,function(x) return fn(tbl[i](x)) end)
        end
    end

    return f(2,tbl[1])
end

-- テーブルからキーの値を取得する M.pipe({{"hoge","fuga"},M.get(1)}) == "hoge"
function M.get(key) return function(tbl)
    return tbl[key]
end end

function M.flip(fn) return function(x) return function(y)
    return fn(y)(x)
end end end

function M.fold(fn) return function(tbl)
    local function f(result,i)
        if tbl[i] == nil then
            return result
        else
            return f(fn(result,tbl[i]),i + 1)
        end
    end

    return f(tbl[1],2)
end end

function M.curry(n) return function(fn)
    n = n or 2
    local function loop(args)
        if #args >= n then
            return fn(unpack(args))
        else
            return function(x)
                local args = vim.deepcopy(args)
                table.insert(args,x)
                return loop(args)
            end
        end
    end
    return loop({})
end end

function M.equal_to_any_element(cond) return function(x)
    local function f(y) return y == x end
    local match =  M.match(f)(cond)
    if match then
        return true
    else
        return false
    end
end end

function M.range(s) return function(e)
    local t = {}
    for i = s, e do
        table.insert(t,i)
    end
    return t
end end

function M.chunks(size) return function(tbl)
    local t = {}
    local function loop(i)
        if i <= #tbl then
            local sub_idx = math.ceil(i / size)
            t[sub_idx] = t[sub_idx] or {}
            table.insert(t[sub_idx],tbl[i])
            loop(i + 1)
        end
    end
    loop(1)

    return t
end end

return M
