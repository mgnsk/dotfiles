function _G.file_size()
	local file = vim.fn.expand("%:p")
	if string.len(file) == 0 then
		return ""
	end

	local size = vim.fn.getfsize(file)
	if size <= 0 then
		return ""
	end

	local units = { "B", "KB", "MB", "GB" }

	local i = 1
	while size > 1024 do
		size = size / 1024
		i = i + 1
	end

	local unit = units[i]
	local format = unit == "B" and "%.0f%s" or "%.1f%s"
	return string.format(format, size, unit)
end

function _G.git_status_line()
	local s = {}

	if vim.b.gitsigns_status_dict then
		table.insert(s, string.format("(%s)", vim.b.gitsigns_status_dict["head"]))
	end

	if vim.b.gitsigns_status ~= "" then
		table.insert(s, vim.b.gitsigns_status)
	end

	if #s > 0 then
		return table.concat(s, " ")
	end

	return ""
end

vim.opt.statusline = table.concat({
	"%#LineNr#",
	"%{v:lua.git_status_line()}",
	"%#LineNr#",
	" %m%f",
	"%=",
	"%#LineNr#",
	" %y",
	" %{&fileencoding?&fileencoding:&encoding}",
	"[%{&fileformat}]",
	" %{v:lua.file_size()}",
	" %p%%",
	" %l:%c",
})
