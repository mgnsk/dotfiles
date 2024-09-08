vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	pattern = {
		"docker-compose*.yml",
		"docker-compose*.yaml",
		"compose*.yml",
		"compose*.yaml",
	},
	callback = function()
		vim.bo.filetype = "yaml.docker-compose"
	end,
})
