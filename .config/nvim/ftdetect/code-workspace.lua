vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	pattern = "*.code-workspace",
	callback = function()
		vim.bo.filetype = "json"
	end,
})
