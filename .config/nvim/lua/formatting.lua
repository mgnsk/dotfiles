local function f(cmd, ...)
    local args = {...}
    return {
        function()
            return {
                exe = cmd,
                args = args,
                stdin = false
            }
        end
    }
end

require "formatter".setup {
    filetype = {
        -- TODO not supported yet
        -- ["*"] = f("sed -i 's/[ \t]*$//'"), -- remove trailing whitespace
        css = f("prettier", "-w"),
        scss = f("prettier", "-w"),
        yaml = f("prettier", "-w"),
        markdown = f("prettier", "-w"),
        html = f("prettier", "-w"),
        json = f("prettier", "-w"),
        javascript = f("prettier", "-w"),
        typescript = f("prettier", "-w"),
        glsl = f("clang-format", "-i"),
        proto = f("clang-format", "-i"),
        dockerfile = f("dockerfile_format"),
        go = f("goimports", "-w"),
        lua = f("luafmt", "-w", "replace"),
        rust = f("rustfmt"),
        sh = f("shfmt", "-w"),
        sql = f("~/.tools/js/sql_format.mjs")
    }
}

vim.api.nvim_exec(
    [[
augroup FormatAutogroup
  autocmd!
  autocmd BufWritePost *.css,*.scss,*.vert,*.tesc,*.tese,*.geom,*.frag,*.comp,*.glsl,*Dockerfile,*go,*.html,*.json,*.js,*.mjs,*.md,*.ts,*.lua,*.proto,*.rs,*.sh,*.sql,*.yml,*.yaml call fns#Format()
augroup END
]],
    true
)
