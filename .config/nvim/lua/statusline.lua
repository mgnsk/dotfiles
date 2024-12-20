--- @return string
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

--- @return string
function _G.num_selected()
	if vim.fn.mode() == "V" then
		local count = math.abs(vim.fn.line(".") - vim.fn.line("v")) + 1

		return string.format("%d", count)
	end

	return ""
end

---@return string
function _G.git_branch()
	local data = vim.api.nvim_call_function("fugitive#statusline", {})
	local branch = string.sub(data, 5, -2)

	return branch
end

vim.opt.statusline = table.concat({
	"%#LineNr#",
	"%{v:lua.git_branch()}",
	" %m%f",
	" %{%v:lua.num_selected()%}",
	"%=",
	"%#LineNr#",
	" %y",
	" %{&fileencoding?&fileencoding:&encoding}",
	"[%{&fileformat}]",
	" %{v:lua.file_size()}",
	" %p%%",
	" %l:%c",
})
