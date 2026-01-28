--- @type LazySpec[]
return {
	{
		"nvim-treesitter/nvim-treesitter",
		dir = vim.fn.expand("$HOME/.nvim-plugins/nvim-treesitter"),
		lazy = false,
	},
	{
		"MeanderingProgrammer/treesitter-modules.nvim",
		dir = vim.fn.expand("$HOME/.nvim-plugins/treesitter-modules.nvim"),
		lazy = false,
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		---@module 'treesitter-modules'
		---@type ts.mod.UserConfig
		opts = {
			auto_install = true,
			ignore_install = {
				"gitcommit",
			},
			indent = { enable = true },
			highlight = {
				enable = true,
				disable = function(ctx)
					local bufsize = vim.api.nvim_buf_get_offset(ctx.buf, vim.api.nvim_buf_line_count(ctx.buf))
					if bufsize > require("const").treesitter_max_filesize then
						return true
					end
					return false
				end,
			},
			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = "<cr>",
					node_incremental = "<tab>",
					scope_incremental = "<cr>",
					node_decremental = "<s-tab>",
				},
			},
		},
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		dir = vim.fn.expand("$HOME/.nvim-plugins/nvim-treesitter-context"),
		event = "VeryLazy",
		---@type TSContext.UserConfig
		opts = {
			multiline_threshold = 1, -- Maximum number of lines to show for a single context
		},
	},
}
