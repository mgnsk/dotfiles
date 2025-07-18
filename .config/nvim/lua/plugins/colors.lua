--- @type LazySpec[]
return {
	{
		"Mofiqul/vscode.nvim",
		dir = vim.fn.expand("$HOME/nvim-plugins/vscode.nvim"),
		config = function()
			vim.o.background = os.getenv("THEME") or "dark"

			local vscode = require("vscode")
			local c = require("vscode.colors").get_colors()

			local cfg = {
				transparent = true,
				-- Enable italic comment
				italic_comments = true,

				color_overrides = {},

				group_overrides = {
					SpellBad = { fg = c.vscRed, underline = true },
					SpellCap = { link = "SpellBad" },
					SpellRare = { link = "SpellBad" },
					SpellLocal = { link = "SpellBad" },
					CSpellBad = { link = "SpellBad" },
					Type = { fg = c.vscBlueGreen, bg = "NONE" },
					TypeDef = { fg = c.vscBlueGreen, bg = "NONE" },
					QuickfixLine = { fg = "NONE", bg = c.vscTabCurrent },
					StatusLine = { fg = "NONE", bg = "NONE" },
					["@variable.builtin"] = { fg = c.vscLightBlue, bg = "NONE" },
					["@module"] = { fg = c.vscLightBlue, bg = "NONE" },
					["@keyword"] = { fg = c.vscPink, bg = "NONE" },

					["@constructor"] = { link = "@function.call" },
					["@function.macro"] = { fg = c.vscPink, bg = "NONE" },
					["@type.builtin"] = { fg = c.vscBlueGreen, bg = "NONE" },
					["@constant.builtin"] = { fg = c.vscYellowOrange, bg = "NONE" },
					["@constant"] = { link = "@variable" },

					-- typescriptreact: TODO:
					["typescriptArrowFunc"] = { fg = c.vscFront, bg = "NONE" },
					-- ["typescriptBlock"] = { fg = c.vscFront, bg = "NONE" },
					["typescriptImportType"] = { link = "@keyword" },
					["typescriptFuncKeyword"] = { link = "@keyword" },
					["typescriptAliasKeyword"] = { link = "@keyword" },
					["typescriptVariable"] = { link = "@keyword" },
					["typescriptAsyncFuncKeyword"] = { link = "@keyword" },
					["typescriptOperator"] = { link = "@keyword" },
					["typescriptKeywordOp"] = { link = "@keyword" },
					["typescriptCastKeyword"] = { link = "@keyword" },
					["typescriptTry"] = { link = "@keyword" },
					["typescriptExceptions"] = { link = "@keyword" },
					["typescriptIdentifierName"] = { link = "@variable" }, -- TODO: not working
					["typescriptNull"] = { link = "@constant.builtin" },
				},
			}

			if vim.o.background == "dark" then
				local bg = "#101010"
				cfg.color_overrides.vscBack = bg
				cfg.group_overrides.TabLine = { fg = c.vscGray, bg = bg }
				cfg.group_overrides.TabLineFill = { fg = c.vscGray, bg = bg }
				cfg.group_overrides.TabLineSel = { fg = c.vscGray, bg = bg }
				cfg.group_overrides.WinSeparator = { fg = bg }
			else
				cfg.group_overrides.TabLineFill = { bg = "NONE" }
				cfg.group_overrides.TabLineSel = { bold = true }
			end

			vscode.setup(cfg)
			vscode.load()
		end,
	},
	{
		"norcalli/nvim-colorizer.lua",
		dir = vim.fn.expand("$HOME/nvim-plugins/nvim-colorizer.lua"),
		ft = { "lua", "html", "css", "less", "typescriptreact", "conf", "toml", "dosini" },
		opts = {
			["*"] = {
				RGB = true,
				RRGGBB = true,
				names = true,
				rgb_fn = true,
				hsl_fn = true,
				css = true,
			},
		},
	},
}
