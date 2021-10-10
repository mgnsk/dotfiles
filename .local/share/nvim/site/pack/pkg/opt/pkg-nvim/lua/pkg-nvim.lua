local PATH = vim.fn.stdpath("data") .. "/site/pack/pkg/start/"
local GITHUB = "https://github.com/"
local REPO_RE = "^[%w-]+/([%w-_.]+)$"
local packages = {}

local function install_pkg(url, dir)
    local file
    if vim.fn.isdirectory(dir) ~= 0 then
        file = io.popen(string.format("cd %s; git pull", dir))
    else
        file = io.popen(string.format("git clone %s %s", url, dir))
    end
    local output = file:read("*all")
    file:close()
    print(output)
end

local function map_pkgs(fn)
    for name, args in pairs(packages) do
        local reponame = name:match(REPO_RE)
        fn(args.url, PATH .. reponame)
    end
end

local function pkg(name)
    packages[name] = {
        url = GITHUB .. name .. ".git"
    }
end

return {
    install = function()
        map_pkgs(install_pkg)
    end,
    pkg = pkg
}
