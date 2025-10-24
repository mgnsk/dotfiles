--- @type LazySpec[]
return {
	{
		"mgnsk/autotabline.nvim",
		dir = vim.fn.expand("$HOME/.nvim-plugins/autotabline.nvim"),
		opts = {},
	},
	{
		"mgnsk/dumb-autopairs.nvim",
		dir = vim.fn.expand("$HOME/.nvim-plugins/dumb-autopairs.nvim"),
		event = "InsertEnter",
		opts = {},
	},
	{
		"kevinhwang91/nvim-fundo",
		dir = vim.fn.expand("$HOME/.nvim-plugins/nvim-fundo"),
		event = "VeryLazy",
		dependencies = {
			{
				"kevinhwang91/promise-async",
				dir = vim.fn.expand("$HOME/.nvim-plugins/promise-async"),
			},
		},
		---@type FundoConfig
		opts = {
			archives_dir = vim.fn.resolve(vim.fn.stdpath("state") .. "/" .. "fundo"),
			limit_archives_size = 64, -- 64M
		},
	},
	{
		"chaoren/vim-wordmotion",
		dir = vim.fn.expand("$HOME/.nvim-plugins/vim-wordmotion"),
	},
	{
		"NlGHT/vim-eel",
		dir = vim.fn.expand("$HOME/.nvim-plugins/vim-eel"),
		ft = "eel2",
	},
}
