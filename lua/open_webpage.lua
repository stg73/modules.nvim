local M = {}

local str = require("string_utils")

function M.open(url)
    local temp = vim.fn.tempname()
    return vim.system({
        "curl",
        "-L",
        url,
        "-o",
        temp
    },vim.schedule_wrap(function(job)
        if job.code == 0 then
            vim.cmd.edit(temp)
            if vim.o.filetype == "" then
                vim.bo.filetype = vim.filetype.match({ filename = str.get.path_of_url(url) or "", buf = 0 }) or "html"
            end
            vim.b.URL = url -- URLが後から分かるように
        else
            vim.fn.feedkeys(":","nx") -- エラー出力の上部に前のメッセージが表示されぬよう
            error("\n> curl -L " .. url .. " -o " .. temp .. "\n" .. job.stderr)
        end
    end)):wait()
end

return M
