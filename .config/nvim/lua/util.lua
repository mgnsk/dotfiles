local M = {}

--- @return string
function M.num_selected()
	if vim.fn.mode() == "V" then
		local count = math.abs(vim.fn.line(".") - vim.fn.line("v")) + 1

		return string.format("%d", count)
	end

	return ""
end

---@return {start_line: number, end_line: number}
function M.selection()
	local cursor_line = vim.fn.line(".")
	local end_line = vim.fn.line("v")

	if cursor_line < end_line then
		return { cursor_line, end_line }
	else
		return { end_line, cursor_line }
	end
end

return M
