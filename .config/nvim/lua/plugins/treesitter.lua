return {
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
				"tlaplus",
				"toml",
				"twig",
				"typescript",
				"yaml",
			}

			if #(vim.api.nvim_list_uis()) > 0 then
				local ok, result = pcall(vim.cmd, string.format("TSUpdate %s", table.concat(parsers, " ")))
				if not ok then
					print(result)
					os.exit(1)
				end
			else
				for _, parser in ipairs(parsers) do
					local ok, result = pcall(vim.cmd, string.format("TSUpdateSync %s", parser))
					if not ok then
						print(result)
						os.exit(1)
					end
				end
			end
		end,
		config = function()
			require("nvim-treesitter.configs").setup({
				highlight = {
					enable = true,
					disable = function(lang, buf)
						local max_filesize = 500 * 1024
						local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
						if ok and stats and stats.size > max_filesize then
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
