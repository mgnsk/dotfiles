local autoformat_enabled = true

function autoformat_toggle()
    autoformat_enabled = not autoformat_enabled
end

vim.cmd("command AutoformatToggle lua autoformat_toggle()")

function _G.doformat()
    if autoformat_enabled then
        vim.cmd("FormatWrite")
    end
end

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
        css = f("prettier", "-w"),
        scss = f("prettier", "-w"),
        markdown = f("prettier", "-w"),
        html = f("prettier", "-w"),
        json = f("prettier", "-w"),
        javascript = f("prettier", "-w"),
        typescript = f("prettier", "-w"),
        glsl = f("clang-format", "-i"),
        proto = f("buf", "format", "-w"),
        c = f("clang-format", "-i"),
        dockerfile = f("dockerfile_format"),
        go = f("goimports", "-w"),
        lua = f("luafmt", "-w", "replace"),
        rust = f("rustfmt"),
        sh = f("shfmt", "-w"),
        sql = f("sqlfmt")
    }
}

-- Remove trailing whitespace and newlines.
vim.api.nvim_command [[augroup TrimTrailingWhiteSpace]]
vim.api.nvim_command [[au!]]
vim.api.nvim_command [[au BufWritePre * %s/\s\+$//e]]
vim.api.nvim_command [[au BufWritePre * %s/\n\+\%$//e]]
vim.api.nvim_command [[augroup END]]

vim.api.nvim_exec(
    [[
augroup FormatAutogroup
  autocmd!
  autocmd BufWritePost *.css,*.scss,*.glsl,*Dockerfile,*.go,*.html,*.json,*.js,*.mjs,*.md,*.ts,*.lua,*.proto,*.c,*.rs,*.sh,*.sql call v:lua.doformat()
augroup END
]],
    true
)
