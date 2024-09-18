vim.g.ts_langs = {
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
	"yaml",
}

function _G.install_ts_lang(lang)
	-- Note: need to use the vim API since treesitter's lua api doesn't throw errors.
	local ok, result = pcall(vim.api.nvim_cmd, { cmd = [[TSUpdateSync]], args = { lang } }, { output = true })
	io.stderr:write(result)
	if not ok then
		os.exit(1)
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

			_G.install_ts_lang("balafon")
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter",
		event = { "BufEnter" },
		init = function() end,
		-- Note: would like to use a function but TSUpdateSync command is not available then (lazy bug?). Instead, need to use a ':' command.
		build = ":lua for _, lang in ipairs(vim.g.ts_langs) do _G.install_ts_lang(lang) end",
		config = function()
			require("nvim-treesitter.configs").setup({
				highlight = {
					enable = true,
					disable = function(_, buf)
						local max_filesize = 1024 * 1024
						local bufsize = vim.api.nvim_buf_get_offset(buf, vim.api.nvim_buf_line_count(buf))
						if bufsize > max_filesize then
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
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		},
		event = { "BufEnter" },
	},
}
