return {
	{
		"mgnsk/autotabline.nvim",
		config = function()
			require("autotabline").setup()
		end,
	},
	{
		"numToStr/Comment.nvim",
		event = "BufEnter",
		config = function()
			require("Comment").setup()
		end,
	},
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = function()
			local ap = require("nvim-autopairs")
			ap.setup({})
			ap.remove_rule([[']])
			ap.remove_rule([["]])
		end,
	},
	{
		"ellisonleao/glow.nvim",
		ft = "markdown",
		init = function()
			vim.api.nvim_create_user_command("MarkdownPreview", function()
				vim.cmd("Glow")
			end, { desc = "Markdown preview" })
		end,
		config = function()
			require("glow").setup({})
		end,
	},
	{
		"mgnsk/table_gen.lua",
		lazy = true,
	},
	{
		"chaoren/vim-wordmotion",
		event = "BufEnter",
	},
	{
		"ojroques/nvim-osc52",
		event = "BufEnter",
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
}
