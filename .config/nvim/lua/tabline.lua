-- Inspired by:
-- https://stackoverflow.com/questions/33710069/how-to-write-tabline-function-in-vim/33765365#33765365
-- https://github.com/lukelbd/vim-tabline
-- https://gist.github.com/neilmarion/6432019

function _G.tab_line()
	local tabline = {}
	local tabtexts = {} -- Tabtexts is just texts without highlight to calculate tabline width.

	-- Loop through tabs.
	for t = 1, vim.fn.tabpagenr("$") do
		local tab = {}
		local tabtext = {}

		if t == vim.fn.tabpagenr() then
			table.insert(tab, "%#TabLineSel#")
		else
			table.insert(tab, "%#TabLine#")
		end

		-- Set the tab page number for mouse clicks.
		table.insert(tab, string.format("%%%dT ", t))
		table.insert(tabtext, " ")

		-- Set the tab number string.
		table.insert(tab, string.format("%d ", t))
		table.insert(tabtext, string.format("%d ", t))

		local name = {}
		local modified = 0
		local buflist = vim.fn.tabpagebuflist(t)

		-- Loop through each buffer in the tab
		for _, b in ipairs(buflist) do
			local buftype = vim.fn.getbufvar(b, "&buftype")
			local bufname = vim.fn.bufname(b)

			if buftype == "help" then
				table.insert(name, "[H]" .. vim.fn.fnamemodify(bufname, ":t:s/.txt$//"))
				table.insert(name, " ")
			elseif buftype == "quickfix" then
				table.insert(name, "[Q]")
				table.insert(name, " ")
			elseif buftype == "terminal" then
				table.insert(name, "[T]" .. vim.fn.pathshorten(vim.split(bufname, "//")[2]))
				table.insert(name, " ")
			else
				local path = vim.fn.pathshorten(bufname)
				if string.len(path) > 0 then
					table.insert(name, path)
					table.insert(name, " ")
				end
			end

			if vim.fn.getbufvar(b, "&modified") > 0 then
				modified = modified + 1
			end
		end

		-- Add modified label.
		if modified > 0 then
			table.insert(tab, string.format("[%d+]", modified))
			table.insert(tabtext, string.format("[%d+]", modified))
		end

		if #name == 0 then
			table.insert(tab, "[New]")
			table.insert(tabtext, "[New]")
		else
			table.insert(tab, table.concat(name, ""))
			table.insert(tabtext, table.concat(name, ""))
		end

		table.insert(tabline, table.concat(tab, ""))
		table.insert(tabtexts, table.concat(tabtext, ""))
	end

	-- Modify if too long.
	local prefix = ""
	local suffix = ""
	local tabstart = 1
	local tabend = vim.fn.tabpagenr("$")
	local tabpage = vim.fn.tabpagenr()

	local function getlen()
		local n = 0
		for _, v in ipairs(tabtexts) do
			n = n + string.len(v)
		end
		return n
	end

	while getlen() + string.len(prefix) + string.len(suffix) > vim.go.columns do
		if tabend - tabpage > tabpage - tabstart then
			tabline = { unpack(tabline, 1, #tabline - 1) } -- Remove one tab from right.
			tabtexts = { unpack(tabtexts, 1, #tabtexts - 1) }
			suffix = "···"
			tabend = tabend - 1
		else
			tabline = { unpack(tabline, 2, #tabline) } -- Remove one tab from left.
			tabtexts = { unpack(tabtexts, 2, #tabtexts) }
			prefix = "···"
			tabstart = tabstart + 1
		end
	end

	tabline = { prefix, unpack(tabline) }
	table.insert(tabline, suffix)

	-- After the last tab fill with TabLineFill and reset tab page nr.
	table.insert(tabline, "%#TabLineFill#%T")
	-- Add a right-aligned X button to close the current tab with mouse.
	if vim.fn.tabpagenr("$") > 1 then
		table.insert(tabline, "%=%#TabLineFill#%999XX")
	end

	return table.concat(tabline, "")
end

vim.opt.tabline = "%!v:lua.tab_line()"
