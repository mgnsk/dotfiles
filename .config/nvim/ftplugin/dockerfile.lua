vim.bo.expandtab = true
vim.bo.shiftwidth = 4
vim.bo.softtabstop = 4
vim.bo.tabstop = 4

vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*Dockerfile",
	callback = function()
		vim.cmd("silent! retab")
	end,
})
