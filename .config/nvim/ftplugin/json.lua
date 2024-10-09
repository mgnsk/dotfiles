vim.bo.expandtab = true
vim.bo.shiftwidth = 2
vim.bo.softtabstop = 2
vim.bo.tabstop = 2

require("file_actions").configureFormatBeforeSave({ "prettier" })

vim.api.nvim_create_autocmd("CursorMoved", {
	group = vim.api.nvim_create_augroup("jsonpath_winbar", {}),
	callback = function()
		vim.opt_local.winbar = require("jsonpath").get(nil, 0)
	end,
})
