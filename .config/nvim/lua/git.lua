vim.keymap.set(
	"n",
	"<leader>W",
	":Gw!<CR>",
	{ desc = "Select the current buffer when resolving git conflicts using vim-fugitive" }
)

require("gitsigns").setup({
	signs = {
		add = { text = "+" },
		change = { text = "~" },
		delete = { text = "-" },
		topdelete = { text = "‾" },
		changedelete = { text = "~" },
		untracked = { text = "┆" },
	},
	status_formatter = nil, -- Use default
})

vim.keymap.set("n", "gn", function()
	require("gitsigns").nav_hunk("next")
end, { desc = "Goto next git hunk" })

vim.keymap.set("n", "gp", function()
	require("gitsigns").nav_hunk("prev")
end, { desc = "Goto prev git hunk" })
