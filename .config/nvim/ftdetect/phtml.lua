vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	pattern = "*.phtml",
	callback = function()
		vim.bo.filetype = "phtml"
	end,
})
