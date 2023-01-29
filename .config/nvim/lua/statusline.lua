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

local function status_line()
    return table.concat({
        "%#LineNr#",
        "%{FugitiveStatusline()}",
        " %{get(b:,'gitsigns_status','')}",
        "%#LineNr#",
        " %m",
        " %f",
        "%=",
        "%#LineNr#",
        " %y",
        " %{&fileencoding?&fileencoding:&encoding}",
        "[%{&fileformat}]",
        " %{v:lua.file_size()}",
        " %p%%",
        " %l:%c",
    })
end

vim.opt.statusline = status_line()
