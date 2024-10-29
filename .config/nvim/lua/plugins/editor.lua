--- @type LazySpec[]
return {
	{
		"mgnsk/autotabline.nvim",
		config = function()
			require("autotabline").setup()
		end,
	},
	{
		"mgnsk/dumb-autopairs.nvim",
		event = "InsertEnter",
		opts = {},
	},
	{
		"kevinhwang91/nvim-fundo",
		event = "BufEnter",
		dependencies = {
			"kevinhwang91/promise-async",
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
	},
}
