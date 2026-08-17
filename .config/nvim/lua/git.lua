vim.keymap.set(
	"n",
	"<leader>W",
	":Gw!<CR>",
	{ desc = "Select the current buffer when resolving git conflicts using vim-fugitive" }
)

vim.schedule(function()
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
end)

vim.keymap.set("n", "gn", function()
	require("gitsigns").nav_hunk("next")
end, { desc = "Goto next git hunk" })

vim.keymap.set("n", "gp", function()
	require("gitsigns").nav_hunk("prev")
end, { desc = "Goto prev git hunk" })

-- Open all folds when viewing diffs (e.g., mergetool / git diffs)
vim.api.nvim_create_autocmd({ "BufWinEnter", "BufReadPost", "VimEnter", "FileType" }, {
	callback = function()
		if vim.wo.diff then
			-- open all folds
			vim.cmd("normal! zR")
			-- ensure foldlevel is high so folds stay open
			vim.wo.foldlevel = 99
		end
	end,
})
