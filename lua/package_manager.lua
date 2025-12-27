local M = {}

local s = require("string_utils")
local r = require("regex")
local t = require("tbl")

function M.lazy(opt) return function(callback)
    -- 特定のキーが押されたらloadする
    local function load_map(mode,map)
        vim.keymap.set(mode,map,function()
            vim.keymap.del(mode,map)
            callback()
            return map
        end,{ expr = true, desc = opt.desc })
    end

    if opt.event then
        vim.api.nvim_create_autocmd(opt.event,{
            pattern = opt.pattern,
            callback = callback,
            once = true,
            desc = opt.desc,
        })
    end
    if opt.nmap then
        load_map("n",opt.nmap)
    end
    if opt.tmap then
        load_map("n",opt.tmap)
    end
    if opt.vmap then
        load_map("n",opt.vmap)
    end
    if opt.imap then
        load_map("n",opt.imap)
    end
    if opt.omap then
        load_map("n",opt.omap)
    end
    if opt.cmap then
        load_map("n",opt.cmap)
    end
    if opt.command then
        vim.api.nvim_create_user_command(opt.command,function(opts)
            vim.api.nvim_del_user_command(opt.command)
            callback()
            local command_exists = vim.api.nvim_get_commands({})[opt.command]
            if command_exists then
                vim.cmd({ cmd = opt.command, args = opts.fargs })
            end
        end,{ nargs = "*", desc = opt.desc })
    end
end end

-- パッケージを管理するディレクトリを決める
function M.directory(d)
    local dir = r.remove("//$")(d)
    local available_packages = dir .. "/available_packages.json"

    local D = {}

    local f = io.open(available_packages,"r")
    D.available_packages = vim.json.decode(f:read("a"))
    f:close()

    function D.same_package(pkg1) return function(pkg2)
        local repo = pkg1.repo == pkg2.repo
        if pkg1.branch then
            return repo and pkg1.branch == pkg2.branch
        elseif pkg1.tag then
            return repo and pkg1.tag == pkg2.tag
        else
            return repo
        end
    end end

    function D.is_installed(pkg)
        return t.match(D.same_package(pkg))(vim.tbl_values(D.available_packages))
    end

    -- vim.system のエラー出力用
    local on_exit = vim.schedule_wrap(function(job)
        if job.code ~= 0 then
            error(str.remove.trailing_space(job.stderr))
        end
    end)

    function D.install(name) return function(pkg)
        if pkg.requires then
            D.install()(pkg.requires)
        end

        local pkg = (type(pkg) == "string") and { repo = pkg } or pkg
        pkg.repo = not r.has("^.+:////")(pkg.repo) and "https://github.com/" .. pkg.repo or pkg.repo -- URLスキームが無ければgithubを使う
        local name = (type(name) == "string") and name or vim.fs.basename(pkg.repo)

        if D.is_installed(pkg) then
            return
        end

        local function hoge(str1,str2)
            if str1 and str2 then
                return str1,str2
            else
                return nil
            end
        end

        vim.system({
            "git","-C",dir,
            "clone",pkg.repo,name,
            "--depth","1","--recursive",
            hoge("--branch",pkg.branch or pkg.tag),
        },on_exit)

        D.available_packages[name] = pkg
        local f = io.open(available_packages,"w")
        f:write(vim.json.encode(D.available_packages))
        f:close()

        return name
    end end

    function D.uninstall(name)
        local pkg_path = dir .. "/" .. name

        vim.fs.rm(pkg_path,{
            recursive = true,
            force = true
        })
        D.available_packages[name] = nil
        local f = io.open(available_packages,"w")
        f:write(vim.json.encode(D.available_packages))
        f:close()

        return name
    end

    D.install_table = t.foreach(D.install)

    function D.update(name)
        vim.system({"git","-C",dir .. "/" .. name,"pull","--rebase"},on_exit)

        return name
    end

    -- runtimepathに追加 の上位互換
    function D.load(name)
        vim.opt.runtimepath:append(dir .. "/" .. name)

        if vim.v.vim_did_enter ~= 0 then
            -- vimの代わりに plugin ディレクトリにあるファイルをソースする
            local plugin = dir .. "/" .. name .. "/plugin"
            local sourceable = r.is(".+/.(lua|vim)")
            local files = vim.fs.find(sourceable,{ path = plugin, type = "file", limit = math.huge })
            t.map(vim.cmd.source)(files)
        end
    end

    function D.is_loaded(name)
        local path = r.gsub("////")("//")(dir .. "/" .. name)
        return r.has("/V," .. path .. "/v(,|$)")(vim.o.runtimepath)
    end

    function D.load_opt(name) return function(opt)
        -- 1回超過loadしないように
        if D.is_loaded(name) then
            return
        end

        if opt.setup then
            opt.setup()
        end

        local function load()
            D.load(name)
            if opt.config then
                opt.config()
            end
        end
        if opt.lazy then
            opt.lazy.desc = "load " .. name
            M.lazy(opt.lazy)(load)
        else
            load()
        end
    end end

    D.load_table = t.foreach(D.load_opt)

    return D
end

return M
