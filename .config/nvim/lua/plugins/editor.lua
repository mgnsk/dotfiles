--- @type LazySpec[]
return {
	{
		"mgnsk/autotabline.nvim",
		dir = vim.fn.expand("$HOME/nvim-plugins/autotabline.nvim"),
		event = "VeryLazy",
		config = function()
			require("autotabline").setup()
		end,
	},
	{
		"mgnsk/dumb-autopairs.nvim",
		dir = vim.fn.expand("$HOME/nvim-plugins/dumb-autopairs.nvim"),
		event = "InsertEnter",
		opts = {},
	},
	{
		"kevinhwang91/nvim-fundo",
		dir = vim.fn.expand("$HOME/nvim-plugins/nvim-fundo"),
		event = "VeryLazy",
		dependencies = {
			{
				"kevinhwang91/promise-async",
				dir = vim.fn.expand("$HOME/nvim-plugins/promise-async"),
			},
		},
		config = function()
			vim.o.undofile = true
			vim.o.swapfile = false
			vim.o.backup = false

			require("fundo").setup({
				archives_dir = vim.fn.resolve(vim.fn.stdpath("state") .. "/" .. "fundo"),
				limit_archives_size = 64, -- 64M
			})
		end,
	},
	{
		"chaoren/vim-wordmotion",
		dir = vim.fn.expand("$HOME/nvim-plugins/vim-wordmotion"),
	},
	{
		"mfussenegger/nvim-ansible",
		dir = vim.fn.expand("$HOME/nvim-plugins/nvim-ansible"),
	},
}
