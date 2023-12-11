local function install(parsers)
	if #(vim.api.nvim_list_uis()) > 0 then
		vim.cmd(string.format("TSUpdate %s", table.concat(parsers, " ")))
	else
		for _, parser in ipairs(parsers) do
			local ok, result = pcall(vim.cmd, string.format("TSUpdateSync %s", parser))
			if not ok then
				print(result)
				os.exit(1)
			end
		end
	end
end

return {
	{
		"mgnsk/tree-sitter-balafon",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		},
		build = function()
			local parser_config = require("nvim-treesitter.parsers").get_parser_configs()

			parser_config.balafon = {
				install_info = {
					url = "https://github.com/mgnsk/tree-sitter-balafon",
					files = { "src/parser.c" },
					branch = "main",
					generate_requires_npm = true,
					requires_generate_from_grammar = false,
				},
				filetype = "bal",
			}

			install({ "balafon" })
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter",
		event = { "BufEnter" },
		build = function()
			local parsers = {
				"bash",
				"beancount",
				"c",
				"comment",
				"cpp",
				"css",
				"dockerfile",
				"glsl",
				"go",
				"gomod",
				"gosum",
				"gowork",
				"html",
				"javascript",
				"lua",
				"php",
				"proto",
				"python",
				"query",
				"rust",
				"sql",
				"svelte",
				"tlaplus",
				"toml",
				"twig",
				"typescript",
				"yaml",
			}

			install(parsers)
		end,
		config = function()
			require("nvim-treesitter.configs").setup({
				highlight = {
					enable = true,
					disable = function(lang, buf)
						local max_filesize = 1024 * 1024
						local size = require("util").buf_size(buf)
						if size > max_filesize then
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
				-- auto_install = true,
				-- textobjects = { enable = true },
			})
		end,
	},
	{
		"nvim-treesitter/playground",
		event = { "BufEnter" },
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		},
	},
}
