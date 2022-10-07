local util = require("formatter.util")

local autoformat_enabled = true

_G.autoformat_toggle = function()
    autoformat_enabled = not autoformat_enabled
end

vim.cmd("command AutoformatToggle lua autoformat_toggle()")

local function doformat()
    if autoformat_enabled then
        vim.cmd("FormatWrite")
    end
end

local function filepath()
    return util.escape_path(util.get_current_buffer_file_path())
end

local function basename()
    local _, name = string.match(filepath(), "^(.-)[\\/]?([^\\/]*)$")
    return name
end

local function f(cmd, ...)
    local args = { ... }
    return {
        function()
            return {
                exe = cmd,
                args = args,
                stdin = false,
                -- Formatter mushes the original file suffix.
                tempfile_postfix = basename(),
            }
        end,
    }
end

require("formatter").setup({
    filetype = {
        css = f("prettier", "-w"),
        scss = f("prettier", "-w"),
        markdown = f("prettier", "-w"),
        html = f("prettier", "-w"),
        json = f("prettier", "-w"),
        javascript = f("prettier", "-w"),
        typescript = f("prettier", "-w"),
        -- glsl = f("clang-format", "-i"),
        proto = f("buf", "format", "-w"),
        -- c = f("clang-format", "-i"),
        dockerfile = f("dockerfile_format"),
        go = f("goimports", "-w"),
        lua = f("stylua", "--indent-type", "Spaces", "--indent-width", "4"),
        rust = f("rustfmt"),
        sh = f("shfmt", "-w"),
        sql = f("pg_format", "-i", "--type-case", "0"),
    },
})

local auTrim = vim.api.nvim_create_augroup("TrimTrailingWhiteSpace", { clear = false })
vim.api.nvim_create_autocmd("BufWritePre", {
    group = auTrim,
    pattern = "*",
    command = [[%s/\s\+$//e]],
})
vim.api.nvim_create_autocmd("BufWritePre", {
    group = auTrim,
    pattern = "*",
    command = [[%s/\n\+\%$//e]],
})

local auFormat = vim.api.nvim_create_augroup("FormatAutogroup", { clear = false })
vim.api.nvim_create_autocmd("BufWritePost", {
    group = auFormat,
    pattern = "*.css,*.scss,*.glsl,*Dockerfile,*.go,*.html,*.json,*.js,*.mjs,*.md,*.ts,*.lua,*.proto,*.c,*.rs,*.sh,*.sql",
    callback = doformat,
})
