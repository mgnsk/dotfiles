vim.g.netrw_banner = 0
-- Tree view.
vim.g.netrw_liststyle = 3
vim.g.netrw_bufsettings = "noma nomod nu nobl nowrap ro"
-- Open files in new tab.
vim.g.netrw_browse_split = 3
-- Preview in vertical split.
vim.g.netrw_preview = 1
vim.g.netrw_alto = 0
vim.g.netrw_winsize = 30

require("oil").setup({
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
	-- Don't disable netrw.
	default_file_explorer = false,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = "oil_preview",
	callback = function(params)
		vim.keymap.set("n", "<CR>", "y", { buffer = params.buf, remap = true, nowait = true })
	end,
})

vim.keymap.set("n", "-", ":Oil<CR>", { desc = "Open Oil file browser" })
vim.keymap.set(
	"n",
	"<leader>e",
	":let $curdir=expand('%:p:h')<CR>:tabnew<CR>:e $curdir<CR>",
	{ desc = "Open netrw file browser in tab" }
)
