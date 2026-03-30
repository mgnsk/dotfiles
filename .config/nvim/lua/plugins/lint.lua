--- @type LazySpec[]
return {
	{
		"mfussenegger/nvim-lint.git",
		dir = vim.fn.expand("$HOME/.nvim-plugins/nvim-lint"),
		-- lazy = true,
		config = function()
			-- Override revive.
			local revive = require("lint").linters.revive
			revive.cmd = "revive_custom"
		end,
	},
}
