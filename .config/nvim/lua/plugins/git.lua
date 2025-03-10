--- @type LazySpec[]
return {
	{
		"tpope/vim-fugitive",
		dir = vim.fn.stdpath("config") .. "/plugins/vim-fugitive",
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
