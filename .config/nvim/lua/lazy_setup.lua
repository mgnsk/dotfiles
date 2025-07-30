-- Bootstrap lazy.nvim
local lazypath = vim.fn.expand("$HOME/.nvim-plugins/lazy.nvim")
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
require("lazy").setup({
	change_detection = { notify = false },
	spec = {
		-- import your plugins
		{ import = "plugins" },
	},
})
