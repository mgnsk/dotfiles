--- @type LazySpec[]
return {
	{
		"mgnsk/tree-sitter-balafon",
		dir = vim.fn.stdpath("data") .. "/plugins/tree-sitter-balafon",
	},
	{
		"nvim-treesitter/nvim-treesitter",
		dir = vim.fn.stdpath("data") .. "/plugins/nvim-treesitter",
		dependencies = {
			"mgnsk/tree-sitter-balafon",
		},
		event = "VeryLazy",
		config = function()
			local parser_config = require("nvim-treesitter.parsers").get_parser_configs()

			parser_config["balafon"] = {
				install_info = {
					url = vim.fn.stdpath("data") .. "/plugins/tree-sitter-balafon",
					files = { "src/parser.c" },
					generate_requires_npm = true,
					requires_generate_from_grammar = false,
				},
				filetype = "bal",
			}

			require("nvim-treesitter.configs").setup({
				ensure_installed = {
					"balafon",
					"beancount",
					"comment",
					"bash",
					"c",
					"lua",
					"markdown",
					"markdown_inline",
					"python",
					"cpp",
					"css",
					"dockerfile",
					"glsl",
					"go",
					"gomod",
					"gosum",
					"gowork",
					"gotmpl",
					"html",
					"javascript",
					"json",
					"jsonnet",
					"php",
					"proto",
					"query",
					"rust",
					"sql",
					"tlaplus",
					"toml",
					"twig",
					"typescript",
					"tsx",
					"yaml",
					"authzed",
					"nix",
					"vim",
					"vimdoc",
				},
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
		dir = vim.fn.stdpath("data") .. "/plugins/nvim-treesitter-context",
		event = "VeryLazy",
		config = function()
			require("treesitter-context").setup({
				multiline_threshold = 1, -- Maximum number of lines to show for a single context
			})
		end,
	},
	{
		"folke/ts-comments.nvim",
		dir = vim.fn.stdpath("data") .. "/plugins/ts-comments.nvim",
		opts = {},
		event = "VeryLazy",
	},
}
