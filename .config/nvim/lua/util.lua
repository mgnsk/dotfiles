local util = {}

function util.buf_size(buf)
	return vim.api.nvim_buf_get_offset(buf, vim.api.nvim_buf_line_count(buf))
end

function util.map(mode, lhs, rhs, opts_overrides)
	local opts = { noremap = true, silent = true }
	opts = vim.tbl_extend("force", opts, opts_overrides or {})
	vim.keymap.set(mode, lhs, rhs, opts)
end

function util.reverse(t)
	for i = 1, math.floor(#t / 2) do
		local j = #t - i + 1
		t[i], t[j] = t[j], t[i]
	end
end

function util.sort_loclist(loclist)
	table.sort(loclist, function(a, b)
		if a.lnum < b.lnum then
			return true
		elseif a.lnum > b.lnum then
			return false
		end

		return a.col < b.col
	end)
end

return util
