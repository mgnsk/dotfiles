vim.api.nvim_create_autocmd({ "CursorHold" }, {
    callback = vim.diagnostic.open_float,
})

vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained", "InsertLeave" }, {
    callback = function()
        vim.o.relativenumber = true
    end,
})

vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost", "InsertEnter" }, {
    callback = function()
        vim.o.relativenumber = false
    end,
})

vim.api.nvim_create_autocmd("TermOpen", {
    command = [[ startinsert ]],
})

vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*",
    command = [[%s/\s\+$//e]],
})

vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*",
    command = [[%s/\n\+\%$//e]],
})
