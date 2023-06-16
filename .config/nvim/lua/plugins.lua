return {
	{
		"tpope/vim-commentary",
		event = "BufEnter",
	},
	{
		"airblade/vim-gitgutter",
		event = "BufEnter",
	},
	{
		"tpope/vim-fugitive",
		event = "BufEnter",
	},
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = function()
			require("nvim-autopairs").setup({})
		end,
	},
	{
		"simrat39/symbols-outline.nvim",
		lazy = true,
		config = function()
			require("symbols-outline").setup()
		end,
	},
	{
		"ellisonleao/glow.nvim",
		ft = "markdown",
		config = function()
			require("glow").setup({})
		end,
	},
	{
		"mgnsk/table_gen.lua",
		lazy = true,
	},
	"pearofducks/ansible-vim",
	"chaoren/vim-wordmotion",
	{
		"ojroques/nvim-osc52",
		config = function()
			local function copy(lines, _)
				require("osc52").copy(table.concat(lines, "\n"))
			end

			local function paste()
				return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
			end

			vim.g.clipboard = {
				name = "osc52",
				copy = { ["+"] = copy, ["*"] = copy },
				paste = { ["+"] = paste, ["*"] = paste },
			}
		end,
	},
	{
		"mbbill/undotree",
		event = "BufEnter",
	},
}
