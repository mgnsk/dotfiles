return {
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
		config = function()
			require("glow").setup({})
		end,
	},
	{
		"mgnsk/table_gen.lua",
		lazy = true,
	},
	{
		"pearofducks/ansible-vim",
		build = function()
			-- TODO: are the snippets shown at all?
			local script = vim.fn.stdpath("data") .. "/lazy/ansible-vim/UltiSnips/generate.sh"

			local output = vim.fn.system("bash " .. script)

			if vim.v.shell_error ~= 0 then
				vim.notify(output, vim.log.levels.ERROR, { title = "ansible-vim" })
			end
		end,
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
	{
		"mbbill/undotree",
		event = "BufEnter",
	},
}
