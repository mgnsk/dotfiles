return {
	{
		"lewis6991/gitsigns.nvim",
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
		end,
	},
}
