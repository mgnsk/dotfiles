return {
	{
		"mgnsk/autotabline.nvim",
		config = function()
			require("autotabline").setup()
		end,
	},
	{
		"numToStr/Comment.nvim",
		event = "BufEnter",
		config = function()
			require("Comment").setup()
		end,
	},
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = function()
			local ap = require("nvim-autopairs")
			ap.setup({})
		end,
	},
	{
		"mgnsk/table_gen.lua",
		lazy = true,
	},
}
