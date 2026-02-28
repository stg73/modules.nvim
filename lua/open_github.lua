local M = {}

local r = require("regex")

local function hoge(str)
    if r.has("^\\\\c")(str) then
        return r.remove("^\\\\.")(str)
    elseif r.has("^\\\\b")(str) then
        return "refs/heads/" .. r.remove("^\\\\.")(str)
    elseif r.has("^\\\\t")(str) then
        return "refs/tags/" .. r.remove("^\\\\.")(str)
    else
        return "HEAD/" .. str
    end
end

function M.get_from_table(tbl)
    return "raw.githubusercontent.com/" .. tbl.repo .. "/raw/" .. hoge(tbl.commit) .. "/" .. tbl.file
end

function M.get_from_string(str)
    local repo = r.match(".{-}/.{-}/")(str)
    local x = r.remove("^.{-}/.{-}/")(str)
    return "raw.githubusercontent.com/" .. repo .. hoge(x)
end

function M.open(str_or_tbl)
    local url = (function()
        if type(str_or_tbl) == "table" then
            return M.get_from_table(str_or_tbl)
        else
            return M.get_from_string(str_or_tbl)
        end
    end)()
    require("open_webpage").open(url)
    vim.b.github = r.gsub("blob/")("(^([^/]+/){3})@<=")(r.gsub("github.com")("^[^/]+")(vim.b.URL)) -- ブラウザで確認用
end

return M
