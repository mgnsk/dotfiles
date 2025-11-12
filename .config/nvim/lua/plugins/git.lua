--- @type LazySpec[]
return {
	{
		"tpope/vim-fugitive",
		dir = vim.fn.expand("$HOME/.nvim-plugins/vim-fugitive"),
		cmd = "Gvdiffsplit",
		init = function()
			vim.keymap.set(
				"n",
				"<leader>W",
				":Gw!<CR>",
				{ desc = "Select the current buffer when resolving git conflicts" }
			)
		end,
	},
	{
		"lewis6991/gitsigns.nvim",
		dir = vim.fn.expand("$HOME/.nvim-plugins/gitsigns.nvim"),
		event = "BufEnter",
		init = function()
			vim.keymap.set("n", "gn", function()
				require("gitsigns").nav_hunk("next")
			end, { desc = "Goto next git hunk" })

			vim.keymap.set("n", "gp", function()
				require("gitsigns").nav_hunk("prev")
			end, { desc = "Goto prev git hunk" })
		end,
		---@type Gitsigns.Config
		opts = {
			signs = {
				add = { text = "+" },
				change = { text = "~" },
				delete = { text = "-" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
				untracked = { text = "┆" },
			},
			status_formatter = nil, -- Use default
		},
	},
}
