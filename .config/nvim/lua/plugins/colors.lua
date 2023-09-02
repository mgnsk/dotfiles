return {
	{
		"Mofiqul/vscode.nvim",
		config = function()
			vim.o.background = "dark"

			local vscode = require("vscode")
			local c = require("vscode.colors").get_colors()
			local bg = "#101010"

			vscode.setup({
				transparent = true,
				-- Enable italic comment
				italic_comments = true,

				color_overrides = {
					vscBack = bg,
				},

				group_overrides = {
					CSpellBad = { link = "SpellBad" },
					TabLine = { fg = c.vscGray, bg = bg },
					TabLineFill = { fg = c.vscGray, bg = bg },
					TabLineSel = { fg = c.vscFront, bg = bg },
					Type = { fg = c.vscBlueGreen, bg = "NONE" },
					TypeDef = { fg = c.vscBlueGreen, bg = "NONE" },
					QuickfixLine = { fg = "NONE", bg = c.vscTabCurrent },
					["@namespace"] = { fg = c.vscLightBlue, bg = "NONE" },
					["@keyword.function"] = { fg = c.vscPink, bg = "NONE" },
					["@keyword.operator"] = { fg = c.vscPink, bg = "NONE" },
					["@function.macro"] = { fg = c.vscPink, bg = "NONE" },
					["@type.builtin"] = { fg = c.vscBlueGreen, bg = "NONE" },
					["@constant.builtin"] = { fg = c.vscYellowOrange, bg = "NONE" },
					["@constant"] = { link = "@variable" },
				},
			})
			vscode.load()
		end,
	},
	{
		"norcalli/nvim-colorizer.lua",
		ft = { "lua", "html", "css", "less" },
		config = function()
			require("colorizer").setup({
				["*"] = {
					RGB = true,
					RRGGBB = true,
					names = false,
					rgb_fn = true,
					hsl_fn = true,
					css = true,
				},
			})
		end,
	},
}
