local M = {}

-- vim.regexのラッパー
-- string.findのvim.regex版
-- string.subで使いやすいようにインデックスも変更
function M.find(pattern) return function(str)
    local s,e = vim.regex("\\v" .. pattern):match_str(str)

    return s and s + 1,e -- nilに+しないように"and"
end end

-- string.match のvim.regex版
function M.match(pattern) return function(str)
    local s,e = M.find(pattern)(str)

    if s and e then
        return string.sub(str,s,e)
    else
        return nil
    end
end end

-- パターンが含まれているかどうか
function M.has(pattern) return function(str)
    return M.find(pattern)(str) and true or false
end end

-- パターンに完全一致するか
-- M.hasのラッパー
function M.is(pattern)
    return M.has("^" .. pattern .. "$")
end

-- vim.fn.substituteのラッパー
-- subの関数にはテーブルが渡される
function M.substitute(sub) return function(pattern) return function(str)
    if type(sub) == "function" then
        return vim.fn.substitute(str,"\\v" .. pattern,sub,"g")
    else
        return vim.fn.substitute(str,"\\v" .. pattern,sub,"g")
    end
end end end

-- string.gsubのvim regex版
-- vim.fn.substituteのラッパー
-- subの関数には文字列が渡される
function M.gsub(sub) return function(pattern) return function(str)
    if type(sub) == "function" then
        return vim.fn.substitute(str,"\\v" .. pattern,function(t)
            local ret = sub(t[1])
            -- string.gsubのように 返り値が偽であれば置換しない
            if ret then
                return ret
            else
                return t[1]
            end
        end,"g")
    else
        return vim.fn.substitute(str,"\\v" .. pattern,sub,"g")
    end
end end end

-- 文字列を除去することはよくあるので
-- M.gsubのラッパー
M.remove = M.gsub("")

-- 文字か関数で文字列をフィルターする
function M.filter(cond) return function(str)
    if type(cond) == "function" then
        return M.gsub(function(x) -- string.gsubを使ってもよいかもしれない
            if cond(x) then
                return x
            else
                return ""
            end
        end)(".")(str)
    else
        return M.remove("[^" .. cond .. "]")(str)
    end
end end

-- M.matchのマッチした文字列のテーブルを返す版
function M.gmatch(pattern) return function(str)
    local t = {}
    M.gsub(function(x) table.insert(t,x) end)(pattern)(str)

    return t
end end

-- 文字列を特定の文字で分割する
-- M.gamtchのラッパー
function M.split(delimiter)
    return M.gmatch("[^" .. delimiter .. "]+")
end

-- powershellのjoin-pathを一般化したようなもの
function M.concat(delimiter) return function(str1) return function(str2)
    return M.gsub(delimiter)("[^" .. delimiter .. "]@<=$")(str1) .. M.remove("^" .. delimiter)(str2)
end end end

--[[
string.gsubのvim.regex版

M.substituteと違い vim.fn.substituteが使われていない
いろいろ微妙
    M.substituteより遅い
    M.substituteと違い"\1"系が使えない
    マッチした部分を削除して再帰しているため ".@<=."のように後読みする場合 M.substituteと挙動が異なる
    M.substitute(".@<=.",":","123") == "1::"
    M.sub(".@<=.",":","123") == "1:3"
]]
function M.sub(sub) return function(pattern) return function(str)
    local t = {} -- strを分解・置換して格納する
    local function loop(str)
        local s,e = M.find(pattern)(str)
        if s and e then
            local matchd = string.sub(str,s,e)

            if s ~= 1 then
                local unmatchd = string.sub(str,1,s - 1)
                table.insert(t,unmatchd)
            end
            if type(sub) == "function" then -- string.gsubのように 関数で置換できるように
                table.insert(t,sub(matchd) or matchd) -- string.gsubのように 偽を返した場合には置換しない
            else
                table.insert(t,sub)
            end

            return loop(string.sub(str,e + 1))
        else
            table.insert(t,str)
            return table.concat(t,"")
        end
    end
    return loop(str)
end end end

return M
