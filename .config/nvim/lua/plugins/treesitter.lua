local parser_install_dir = vim.fn.stdpath("data") .. "/treesitter"
vim.opt.rtp:append(parser_install_dir)

--- @type LazySpec[]
return {
	{
		"mgnsk/tree-sitter-balafon",
		dir = vim.fn.stdpath("config") .. "/plugins/tree-sitter-balafon",
	},
	{
		"nvim-treesitter/nvim-treesitter",
		dir = vim.fn.stdpath("config") .. "/plugins/nvim-treesitter",
		dependencies = {
			"mgnsk/tree-sitter-balafon",
		},
		version = nil,
		event = "VeryLazy",
		config = function()
			local parser_config = require("nvim-treesitter.parsers").get_parser_configs()

			parser_config["balafon"] = {
				install_info = {
					url = vim.fn.stdpath("config") .. "/plugins/tree-sitter-balafon",
					files = { "src/parser.c" },
					generate_requires_npm = true,
					requires_generate_from_grammar = false,
				},
				filetype = "bal",
			}

			require("nvim-treesitter.configs").setup({
				parser_install_dir = parser_install_dir,
				auto_install = true,
				highlight = {
					enable = true,
					disable = function(_, buf)
						local bufsize = vim.api.nvim_buf_get_offset(buf, vim.api.nvim_buf_line_count(buf))
						if bufsize > require("const").treesitter_max_filesize then
							return true
						end
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
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		dir = vim.fn.stdpath("config") .. "/plugins/nvim-treesitter-context",
		event = "VeryLazy",
		config = function()
			require("treesitter-context").setup({
				multiline_threshold = 1, -- Maximum number of lines to show for a single context
			})
		end,
	},
	{
		"folke/ts-comments.nvim",
		dir = vim.fn.stdpath("config") .. "/plugins/ts-comments.nvim",
		opts = {},
		event = "VeryLazy",
	},
}
