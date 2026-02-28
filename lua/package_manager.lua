local M = {}

local s = require("string_utils")
local r = require("regex")
local t = require("tbl")

-- パッケージを管理するディレクトリを決める
function M.directory(d)
    local dir = r.remove("/$")(d)
    local installed = dir .. "/_installed.json"

    local D = {}

    local f = io.open(installed,"r")
    D.installed = vim.json.decode(f:read("a"))
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
        return t.match(D.same_package(pkg))(vim.tbl_values(D.installed))
    end

    -- vim.system のエラー出力用
    local on_exit = vim.schedule_wrap(function(job)
        if job.code ~= 0 then
            error(vim.trim(job.stderr))
        end
    end)

    function D.install(name) return function(pkg)
        if pkg.requires then
            D.install()(pkg.requires)
        end

        local pkg = (type(pkg) == "string") and { repo = pkg } or pkg
        pkg.repo = not r.has("^.+://")(pkg.repo) and "https://github.com/" .. pkg.repo or pkg.repo -- URLスキームが無ければgithubを使う
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

        D.installed[name] = pkg
        local f = io.open(installed,"w")
        f:write(vim.json.encode(D.installed))
        f:close()

        return name
    end end

    function D.uninstall(name)
        local pkg_path = dir .. "/" .. name

        vim.fs.rm(pkg_path,{
            recursive = true,
            force = true
        })
        D.installed[name] = nil
        local f = io.open(installed,"w")
        f:write(vim.json.encode(D.installed))
        f:close()

        return name
    end


    function D.update(name)
        vim.system({"git","-C",dir .. "/" .. name,"pull","--rebase"},on_exit)

        return name
    end

    D.install_table = t.pairs(function(k_v)
        D.install(k_v[1])(k_v[2])
    end)

    D.loaded = {}
    -- すでに読み込まれたプラグインがあれば入れる
    tbl.map(function(path)
        if r.is(dir) then
            local name = vim.fs.basename(path)
            D.loaded[name] = D.installed[name]
        end
    end)(vim.api.nvim_list_runtime_paths())

    -- runtimepathに追加 の上位互換
    function D.load(name)
        vim.opt.runtimepath:append(dir .. "/" .. name)
        D.loaded[name] = D.installed[name]

        if vim.v.vim_did_enter ~= 0 then
            -- vimの代わりに plugin ディレクトリにあるファイルをソースする
            local plugin = dir .. "/" .. name .. "/plugin"
            local sourceable = r.is(".+\\.(lua|vim)")
            local files = vim.fs.find(sourceable,{ path = plugin, type = "file", limit = math.huge })
            t.map(vim.cmd.source)(files)
        end
    end

    function D.load_opt(name) return function(opt)
        -- 1回超過loadしないように
        if D.loaded[name] then
            return
        end

        if opt.setup then
            opt.setup()
        end

        local function load()
            if opt.hook_pre then
                opt.hook_pre()
            end
            D.load(name)
            if opt.hook_post then
                opt.hook_post()
            end
        end
        if opt.lazy then
            opt.lazy.desc = "load " .. name
            require("lazy_call").lazy(opt.lazy)(load)
        else
            load()
        end
    end end

    D.load_table = t.pairs(function(k_v)
        D.load_opt(k_v[1])(k_v[2])
    end)

    return D
end

return M
