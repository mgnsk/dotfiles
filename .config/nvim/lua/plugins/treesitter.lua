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

--- @type LazySpec[]
return {
	{
		"mgnsk/tree-sitter-balafon",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		},
		event = { "BufEnter" },
		build = function(plugin)
			local parser_config = require("nvim-treesitter.parsers").get_parser_configs()

			parser_config["balafon"] = {
				install_info = {
					url = plugin.dir,
					files = { "src/parser.c" },
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
			install({
				"beancount",
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
				"php",
				"proto",
				"query",
				"rust",
				"sql",
				"tlaplus",
				"toml",
				"twig",
				"typescript",
				"yaml",
			})
		end,
		config = function()
			require("nvim-treesitter.configs").setup({
				highlight = {
					enable = true,
					disable = function(_, buf)
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
