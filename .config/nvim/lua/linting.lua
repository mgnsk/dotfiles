local revive = require("lint").linters.revive
revive.cmd = "revive_custom"

vim.api.nvim_create_user_command("CSpell", function()
	require("lint").try_lint("cspell")
end, { desc = "Run cspell on current buffer" })

vim.keymap.set("n", "<leader>S", function()
	if vim.o.spell then
		vim.o.spell = false
		print("spell off")
	else
		vim.o.spell = true
		print("spell on")
	end
end, { desc = "Toggle vim spell check" })
