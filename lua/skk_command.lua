local M = {}

-- オプションの違いを吸収 -- substituteコマンドをグローバルにする
local function g()
    return vim.o.gdefault and "" or "g"
end

function M.sort(opts) -- "skkdic-expr2"のラッパー
    local current_search = vim.fn.getreg('/')
    if opts.range == 0 then -- 既定のrange
        vim.cmd([[$?;; okuri-ari entries.?;$!skkdic-expr2]]) -- ファイル上部のコメントを削除しない
    else
        vim.cmd(opts.line1 .. "," .. opts.line2 .. "!skkdic-expr2")
    end
    vim.fn.setreg('/',current_search)
    vim.cmd.nohlsearch()
end

function M.annotate(opts)
    if vim.b.skk_bunnrui then
        local current_search = vim.fn.getreg('/')
        local e = "/e" .. g()
        vim.cmd(opts.line1 .. ',' .. opts.line2 .. "global/\\v^(;; )@!/" .. [[substitute/\v(\/[^;]+)@<=\/@=/;]] .. e .. [[ | substitute/\v;@<=(\[]] .. vim.b.skk_bunnrui .. [[\])@!/\[]] .. vim.b.skk_bunnrui .. "\\]" .. e)
        vim.fn.setreg('/',current_search)
        vim.cmd.nohlsearch()
    end
end

function M.count_annotation_errors(opts)
    local current_search = vim.fn.getreg('/')
    vim.cmd.skkSearchAnnotationErrors()
    vim.cmd(opts.line1 .. "," .. opts.line2 .. [[substitute///ne]] .. g())
    vim.fn.setreg('/',current_search)
    vim.cmd.nohlsearch()
end

function M.search_annotation_errors(opts)
    if vim.b.skk_bunnrui then
        vim.fn.setreg('/',[[\v\/@<=([^/]+;\[]] .. vim.b.skk_bunnrui .. [[\])@![^/]+]])
    end
end

function M.search_midasi_kouho(opts)
    vim.fn.setreg('/',[[\v(^(;; )@!.+ .*\/)@<=[^/]+]])
end

return M
