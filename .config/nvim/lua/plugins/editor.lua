return {
	{
		"mgnsk/autotabline.nvim",
		config = function()
			require("autotabline").setup()
		end,
	},
	{
		"mbbill/undotree",
		event = "BufEnter",
		build = function(plugin)
			vim.cmd.helptags(plugin.dir .. "/doc")
		end,
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
}
