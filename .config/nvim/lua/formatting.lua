local autoformat_enabled = true

_G.autoformat_toggle = function()
    autoformat_enabled = not autoformat_enabled
end

vim.cmd("command AutoformatToggle lua autoformat_toggle()")

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

local function f(cmd, ...)
    local args = { ... }
    return function()
        if not autoformat_enabled then
            return
        end

        local bufname = vim.fn.fnameescape(vim.api.nvim_buf_get_name(0))
        local command = string.format("%s %s %s 2>&1", cmd, table.concat(args, " "), bufname)

        local f = assert(io.popen(command, "r"))
        local output = assert(f:read("*a"))
        local rc = { f:close() }

        if rc[3] ~= 0 then
            vim.notify(output, vim.log.levels.ERROR, { title = "Formatter" })
        end

        vim.cmd([[silent! edit]])
    end
end

local auFormat = vim.api.nvim_create_augroup("FormatAutogroup", { clear = false })

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = auFormat,
    pattern = { "*.css", "*.less", "*.scss", "*.md", "*.html", "*.json", "*.js", "*.ts" },
    callback = f("prettier", "-w"),
})

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = auFormat,
    pattern = { "*.lua" },
    callback = f("stylua", "--indent-type", "Spaces", "--indent-width", "4"),
})

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = auFormat,
    pattern = { "*.c", "*.glsl" },
    callback = f("clang-format", "-i"),
})

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = auFormat,
    pattern = { "*.proto" },
    callback = f("buf", "format", "-w"),
})

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = auFormat,
    pattern = { "*Dockerfile" },
    callback = f("dockerfile_format"),
})

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = auFormat,
    pattern = { "*.go" },
    callback = f("goimports", "-w"),
})

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = auFormat,
    pattern = { "*.rs" },
    callback = f("rustfmt"),
})

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = auFormat,
    pattern = { "*.sh" },
    callback = f("shfmt", "-w"),
})

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = auFormat,
    pattern = { "*.sql" },
    callback = f("pg_format", "-i", "--type-case", "0"),
})
