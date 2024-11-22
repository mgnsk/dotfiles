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
	"tsx",
	"yaml",
	"authzed",
}

---@param lang string
local function install_ts_lang(lang)
	-- Note: need to use the vim API since treesitter's lua api doesn't throw errors.
	local ok, result = pcall(vim.api.nvim_cmd, { cmd = [[TSUpdateSync]], args = { lang } }, { output = true })
	io.stderr:write(result .. "\n")
	if not ok then
		os.exit(1)
	end
end

---@param langs string[]
function _G.install_ts_langs(langs)
	for _, lang in ipairs(langs) do
		install_ts_lang(lang)
	end
end

--- @type LazySpec[]
return {
	{
		"mgnsk/tree-sitter-balafon",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		},
		ft = "balafon",
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

			install_ts_lang("balafon")
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter",
		-- Note: would like to use a function but TSUpdateSync command is not available then (lazy bug?). Instead, need to use a ':' command.
		build = ":lua _G.install_ts_langs(vim.g.ts_langs)",
		event = "BufEnter",
		config = function()
			require("nvim-treesitter.configs").setup({
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
		event = "VeryLazy",
		config = function()
			require("treesitter-context").setup({
				multiline_threshold = 1, -- Maximum number of lines to show for a single context
			})
		end,
	},
	{
		"folke/ts-comments.nvim",
		opts = {},
		event = "VeryLazy",
	},
}
