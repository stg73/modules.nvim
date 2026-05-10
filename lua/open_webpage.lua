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
            vim.api.nvim_buf_set_name(0,url)
            vim.api.nvim_exec_autocmds("BufRead",{ group = "filetypedetect", buf = 0 })
            vim.api.nvim_buf_set_name(0,temp)
            vim.b.URL = url -- URLが後から分かるように
        else
            vim.fn.feedkeys(":","nx") -- エラー出力の上部に前のメッセージが表示されぬよう
            local prompt = ">"
            local command = ("curl -L %s -o %s"):format(url,temp)
            vim.notify(("\n%s %s\n%s"):format(prompt,command,job.stderr),vim.log.levels.ERROR)
        end
    end)):wait()
end

return M
