--- @type LazySpec[]
return {
	{
		"tpope/vim-fugitive",
		init = function()
			vim.keymap.set(
				"n",
				"<leader>W",
				":Gw!<CR>",
				{ desc = "Select the current buffer when resolving git conflicts" }
			)
		end,
	},
}
