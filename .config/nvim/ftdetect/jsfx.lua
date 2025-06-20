vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	pattern = "*.jsfx",
	callback = function()
		vim.bo.filetype = "eel2"
	end,
})
