local M = {}

-- サブモジュール的な

-- SKKを構文解析する
M.parse = {}
local P = M.parse

-- 最低限のパターンを使って定義しているので M.isで想定している文法要素であるか確認してから使う必要がある つまり "G.midasi_okuri"を使っても"I.okuri_midasi"は判断できない
M.get = {}
local G = M.get

-- ある文法要素であるか判断する
M.is = {}
local I = M.is

-- 出現回数を数える
M.count = {}
local C = M.count

-- 遊び
-- SKK辞書を読み込んで 簡易的な変換をする
M.hennkann = {}
local H = M.hennkann

M.command = {}
local cmd = M.command


local regex = require("regex")
local tbl = require("tbl")

function P.comment(comment)
    local start,content = string.match(comment,"(;+) *(.*)")
    return {
        start = start,
        content = content
    }
end

function P.midasi(midasi)
    if I.okuri_midasi(midasi) then
        return {
            stem = G.midasi_stem(midasi),
            okuri = G.midasi_okuri(midasi)
        }
    else
        return midasi
    end
end

P.kouho_chunk = regex.gmatch("//@<=[^//]+")
-- regex.gmatch("[^//]+") -- 前の定義 なぜかSKK-JISYO.Lでは実際よりも要素の数が大きくなる

function P.kouho(kouho)
    return {
        kouho = G.kouho(kouho),
        annotation = G.annotation(kouho),
    }
end

function P.entry(entry)
    return {
        midasi = P.midasi(G.midasi(entry)),
        kouho_chunk = tbl.pipe({ entry, G.kouho_chunk, P.kouho_chunk, tbl.map(P.kouho) }),
        okuri_chunk = tbl.map_filter(function(x) return x end)(tbl.get(1))(tbl.pipe({ entry, G.okuri_chunk, P.okuri_chunk, tbl.map(P.okuri_chunk_entry) }))
    }
end

function P.line(expr)
    if I.userdict_entry(expr) then
        return {
            P.entry(expr),
            type = "userdict-entry"
        }
    elseif I.entry(expr) then
        return {
            P.entry(expr),
            type = "entry"
        }
    elseif I.okuri_comment(expr) then
        return {
            P.comment(expr),
            type = "okuri-comment"
        }
    elseif I.comment(expr) then
        return {
            P.comment(expr),
            type = "comment"
        }
    else
        return {
            {
                expression = expr
            },
            type = "invalid"
        }
    end
end

-- ユーザ辞書用

G.okuri_chunk = regex.match("//(/[(.+//)+/]//)+")

P.okuri_chunk = regex.gmatch("/[.{-}/]")

function P.okuri_chunk_entry(okuri_chunk)
    return {
        okuri = regex.match("(^.)@<=.")(okuri_chunk),
        stem = regex.gmatch("//@<=[^///[/]]+")(okuri_chunk)
    }
end

-- 複数行のSKKを構文解析
P.expressions = tbl.compose({ tbl.map(P.line), regex.split("\n") })

-- エントリから見出しを取得
G.midasi = regex.match("^/S+")

-- エントリから候補群を取得
G.kouho_chunk = regex.remove("(/[(.+//)+/]//)+|^/S+ ") -- 見出し部と送り厳密部を削除

-- 見出しからそのokuriを取得
G.midasi_okuri = regex.match("/l")

-- 見出しからokuriを除いた語幹を取得
G.midasi_stem = regex.match("[あ-んー]+")

-- 候補と注釈から候補を取得
G.kouho = regex.match("^[^;//]+")

-- 候補と注釈から注釈を取得
G.annotation = regex.match(";@<=[^//]*")

I.entry = regex.is("/S+ //.+//")

-- 角括弧で示される候補の分類を取得
G.bunnrui = tbl.map_filter(regex.match("(^/S+ .+;/[)@<=[^/]]+"))(I.entry)

-- "skk-specialized"のシンタクスハイライトに使われている
function G.bunnrui_from_table(exprs)
    local bunnrui = tbl.match(G.bunnrui)(exprs)
    if bunnrui then
        return G.bunnrui(bunnrui)
    else
        return nil
    end
end

I.userdict_entry = regex.is("/S+ //.+//(/[(.+//)+/]//)+$")

I.comment = regex.is(";+( .+)*")

I.okuri_comment = regex.is(";; okuri-(ari|nasi) entries/.")

I.okuri_midasi = regex.is("[あ-んー]+/l")

C.kouho = tbl.compose({ tbl.fold(function(x,y) return x + y end), tbl.map(table.getn), tbl.map(P.kouho_chunk), tbl.map(G.kouho_chunk), tbl.filter(I.entry) })

C.entry = tbl.compose({ table.getn, tbl.filter(I.entry) })

function C.buf(buf)
    local content = vim.api.nvim_buf_get_lines(buf,0,-1,false)
    return {
        entry = C.entry(content),
        kouho = C.kouho(content)
    }
end

-- 1行のSKKから変換用テーブルを作る
H.get_midasi_kouhos = tbl.map_reverse({ G.midasi, tbl.compose({ tbl.map(G.kouho), P.kouho_chunk, G.kouho_chunk}) })

-- 実際の変換
H.fn = {}

-- バッファからSKKを読み込む
H.fn.buf = function(buf)
    return tbl.pipe({ vim.api.nvim_buf_get_lines(buf,0,-1,false), tbl.filter(I.entry), tbl.map(H.get_midasi_kouhos), tbl.fn })
end

-- 上の逆変換版
H.fn.buf_reverse = function(buf)
    return tbl.pipe({ vim.api.nvim_buf_get_lines(buf,0,-1,false), tbl.filter(I.entry), tbl.map(H.get_midasi_kouhos), tbl.fn_reverse })
end

-- オプションの違いを吸収 -- substituteコマンドをグローバルにする
local function g()
    return vim.o.gdefault and "" or "g"
end

function cmd.sort(opts) -- "skkdic-expr2"のラッパー
    local current_search = vim.fn.getreg('/')
    if opts.range == 0 then -- 既定のrange
        vim.cmd([[$?;; okuri-ari entries.?;$!skkdic-expr2]]) -- ファイル上部のコメントを削除しない
    else
        vim.cmd(opts.line1 .. "," .. opts.line2 .. "!skkdic-expr2")
    end
    vim.fn.setreg('/',current_search)
    vim.cmd.nohlsearch()
end

function cmd.annotate(opts)
    if vim.b.skk_bunnrui then
        local current_search = vim.fn.getreg('/')
        local e = "/e" .. g()
        vim.cmd(opts.line1 .. ',' .. opts.line2 .. "global/\\v^(;; )@!/" .. [[substitute/\v(\/[^;]+)@<=\/@=/;]] .. e .. [[ | substitute/\v;@<=(\[]] .. vim.b.skk_bunnrui .. [[\])@!/\[]] .. vim.b.skk_bunnrui .. "\\]" .. e)
        vim.fn.setreg('/',current_search)
        vim.cmd.nohlsearch()
    end
end

function cmd.count_annotation_errors(opts)
    local current_search = vim.fn.getreg('/')
    cmd.search_annotation_errors()
    vim.cmd(opts.line1 .. "," .. opts.line2 .. [[substitute///ne]] .. g())
    vim.fn.setreg('/',current_search)
    vim.cmd.nohlsearch()
end

function cmd.search_annotation_errors(opts)
    if vim.b.skk_bunnrui then
        vim.fn.setreg('/',[[\v\/@<=([^/]+;\[]] .. vim.b.skk_bunnrui .. [[\])@![^/]+]])
    end
end

function cmd.search_midasi_kouho(opts)
    vim.fn.setreg('/',[[\v(^(;; )@!.+ .*\/)@<=[^/]+]])
end

return M
