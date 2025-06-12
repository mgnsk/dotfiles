--- @type LazySpec[]
return {
	{
		"lewis6991/gitsigns.nvim",
		dir = vim.fn.expand("$HOME/nvim-plugins/gitsigns.nvim"),
		event = "BufEnter",
		config = function()
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
		end,
	},
}
