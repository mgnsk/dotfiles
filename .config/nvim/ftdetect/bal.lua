vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	pattern = "*.bal",
	callback = function()
		vim.bo.filetype = "balafon"
	end,
})
