--- @type LazySpec[]
return {
	{
		"neomake/neomake",
		cond = not os.getenv("NVIM_DIFF"),
		event = "BufEnter",
		config = function()
			vim.g.neomake_open_list = 2
		end,
	},
	{
		"ryuichiroh/vim-cspell",
		event = "BufEnter",
		init = function()
			vim.g.cspell_disable_autogroup = true

			vim.api.nvim_create_user_command("CSpell", function()
				vim.api.nvim_call_function("cspell#lint", {})
			end, { desc = "Run cspell on current buffer" })
		end,
	},
	{
		"phelipetls/jsonpath.nvim",
		lazy = true,
		init = function()
			vim.api.nvim_create_user_command("JSONPath", function()
				vim.fn.setreg("+", require("jsonpath").get(nil, 0))
			end, { desc = "Yank current JSON path to system clipboard" })
		end,
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		},
	},
	{
		"stevearc/oil.nvim",
		cmd = "Oil",
		config = function()
			-- Confirm file operations with <CR>.
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "oil_preview",
				callback = function(params)
					vim.keymap.set("n", "<CR>", "y", { buffer = params.buf, remap = true, nowait = true })
				end,
			})

			local oil = require("oil")

			oil.setup({
				use_default_keymaps = false,
				keymaps = {
					["<CR>"] = "actions.select",
					["<C-v>"] = {
						"actions.select",
						opts = { vertical = true },
						desc = "Open the entry in a vertical split",
					},
					["<C-s>"] = {
						"actions.select",
						opts = { horizontal = true },
						desc = "Open the entry in a horizontal split",
					},
					["<C-t>"] = { "actions.select", opts = { tab = true }, desc = "Open the entry in new tab" },
					["<C-p>"] = "actions.preview",
					["-"] = "actions.parent",
				},
				skip_confirm_for_simple_edits = true,
				view_options = {
					show_hidden = true,
					-- Note: these settings correspond to the order of `ls -Alhv --group-directories-first`.
					natural_order = false,
					sort = {
						{ "type", "asc" },
						{ "name", "asc" },
					},
				},
			})
		end,
		-- -- Optional dependencies
		-- dependencies = { "nvim-tree/nvim-web-devicons" },
	},
}
