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
			require("nvim-autopairs").setup()
		end,
	},

	{
		event = "BufEnter",
		"mbbill/undotree",
		build = function()
			local docPath = vim.fn.resolve(vim.fn.stdpath("data") .. "/lazy/undotree/doc")
			vim.cmd.helptags(docPath)
		end,
	},
}
