vim.o.undofile = true
vim.o.swapfile = false
vim.o.backup = false

require("fundo").setup({
	archives_dir = vim.fn.resolve(vim.fn.stdpath("state") .. "/" .. "fundo"),
	limit_archives_size = 64, -- 64M
})
