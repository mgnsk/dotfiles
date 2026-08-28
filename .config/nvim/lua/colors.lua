vim.o.background = "light"

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

		TabLineFill = { bg = "NONE" },
		TabLineSel = { bold = true },
	},
}

vscode.setup(cfg)
vscode.load()

vim.schedule(function()
	require("colorizer").setup({
		filetypes = { "lua", "html", "css", "less", "typescriptreact", "conf", "toml", "dosini" },
	})

	-- colorizer only attaches via a FileType autocmd registered inside setup(),
	-- so it misses the buffer that was already open when setup() was deferred.
	-- Re-fire that autocmd group to catch it.
	vim.cmd.doautoall("ColorizerSetup FileType")
end)
