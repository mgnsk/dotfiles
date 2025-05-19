--- @type LazySpec[]
return {
	{
		"mgnsk/autotabline.nvim",
		dir = vim.fn.stdpath("config") .. "/plugins/autotabline.nvim",
		event = "VeryLazy",
		config = function()
			require("autotabline").setup()
		end,
	},
	{
		"mgnsk/dumb-autopairs.nvim",
		dir = vim.fn.stdpath("config") .. "/plugins/dumb-autopairs.nvim",
		event = "InsertEnter",
		opts = {},
	},
	{
		"kevinhwang91/nvim-fundo",
		dir = vim.fn.stdpath("config") .. "/plugins/nvim-fundo",
		event = "VeryLazy",
		dependencies = {
			{
				"kevinhwang91/promise-async",
				dir = vim.fn.stdpath("config") .. "/plugins/promise-async",
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
		dir = vim.fn.stdpath("config") .. "/plugins/vim-wordmotion",
	},
	{
		"mfussenegger/nvim-ansible",
		dir = vim.fn.stdpath("config") .. "/plugins/nvim-ansible",
	},
}
