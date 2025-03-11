vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	pattern = "*.gotmpl",
	callback = function()
		vim.bo.filetype = "gotmpl"
	end,
})
