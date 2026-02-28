local M = {}

-- サブモジュール的な

-- 不要な文字列を削除
M.remove = {}
local R = M.remove

-- 何かを取得
M.get = {}
local G = M.get


local regex = require("regex")
local tbl = require("tbl")

R.ansi_escape_code = regex.remove("\\e\\[[0-9;]*m")
R.trailing_space = regex.remove(" +$|\n%$")
R.hoge = tbl.compose({ R.trailing_space, regex.gsub("\n")("([\r\n]*\\s*[\r\n])+") }) -- 変な空白や改行を削除

G.child_item = regex.match("[^/]+(/?$)@=")
G.path_of_url = regex.match("[^/]@<=/[^/].*$")
G.original_name_of_backup_file = regex.remove("(\\.\\d[^.]+)?\\.[^.]+$")

return M
