vim.o.foldnestmax = 3
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("treesitter.setup", {}),
	callback = function(args)
		local buf = args.buf
		local filetype = args.match

		-- you need some mechanism to avoid running on buffers that do not
		-- correspond to a language (like oil.nvim buffers), this implementation
		-- checks if a parser exists for the current language
		local language = vim.treesitter.language.get_lang(filetype) or filetype
		local ok = pcall(vim.treesitter.language.inspect, language)
		if not ok then
			return
		end

		vim.schedule(function()
			vim.treesitter.start(buf, language)

			-- TODO: not working
			vim.wo.foldmethod = "expr"
			vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
		end)

		vim.keymap.set({ "n", "v" }, "<CR>", function()
			if vim.fn.mode() == "v" then
				vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("an", true, false, true), "v", false)
			else
				vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("van", true, false, true), "v", false)
			end
		end, { desc = "Treesitter incremental select", buf = buf })

		vim.keymap.set({ "v" }, "<Tab>", function()
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("an", true, false, true), "v", false)
		end, { desc = "Treesitter incremental select increase", buf = buf })

		vim.keymap.set({ "v" }, "<S-Tab>", function()
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("in", true, false, true), "v", false)
		end, { desc = "Treesitter incremental select decrease", buf = buf })
	end,
})
