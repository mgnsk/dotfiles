vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	pattern = "*.zaml",
	callback = function()
		vim.bo.filetype = "zaml"
	end,
})
