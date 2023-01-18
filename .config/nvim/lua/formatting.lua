vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*",
    command = [[%s/\s\+$//e]],
})

vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*",
    command = [[%s/\n\+\%$//e]],
})

require("formatter").setup({
    css = { "prettier", "-w" },
    less = { "prettier", "-w" },
    markdown = { "prettier", "-w" },
    html = { "prettier", "-w" },
    json = { "prettier", "-w" },
    javascript = { "prettier", "-w" },
    typescript = { "prettier", "-w" },
    lua = { "stylua", "--indent-type", "Spaces", "--indent-width", "4" },
    c = { "clang-format", "-i" },
    glsl = { "clang-format", "-i" },
    proto = { "buf", "format", "-w" },
    dockerfile = { "dockerfile_format" },
    go = { "goimports", "-w" },
    rust = { "rustfmt" },
    sh = { "shfmt", "-w" },
    sql = { "pg_format", "-i", "--type-case", "0" },
})
