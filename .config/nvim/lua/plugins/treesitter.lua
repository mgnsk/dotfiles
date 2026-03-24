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
		config = function()
			require("treesitter-modules").setup({
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
			})

			vim.opt.foldnestmax = 3
			vim.opt.foldlevel = 99
			vim.opt.foldlevelstart = 99

			vim.api.nvim_create_autocmd("FileType", {
				pattern = "*",
				callback = function(opts)
					local lang = vim.treesitter.language.get_lang(opts.match)
					if lang then
						local ok = pcall(vim.treesitter.language.inspect, lang)
						if ok then
							-- Important to schedule this function for performance.
							vim.schedule(function()
								vim.wo.foldmethod = "expr"
								vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
								vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
							end)
						end
					end
				end,
			})
		end,
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
