function _G.tab_line()
    local tabline = {}
    local tabtexts = {} -- tabtexts is just texts without highlight
    local tc = vim.fn.tabpagenr("$")

    for t = 1, tc do
        local tab = {}
        local tabtext = {}

        -- set highlight
        if t == vim.fn.tabpagenr() then
            table.insert(tab, "%#TabLineSel#")
        else
            table.insert(tab, "%#TabLine#")
        end
        -- set the tab page number (for mouse clicks)
        table.insert(tab, string.format("%%%dT ", t))
        table.insert(tabtext, " ")
        -- set page number string
        table.insert(tab, string.format("%d ", t))
        table.insert(tabtext, string.format("%d ", t))

        -- get buffer names and statuses
        local n = {} -- temp string for buffer names while we loop and check buftype
        local m = 0 -- &modified counter
        local buflist = vim.fn.tabpagebuflist(t)
        local bc = #buflist -- counter to avoid last ' '

        -- loop through each buffer in a tab
        for _, b in ipairs(buflist) do
            -- buffer types: quickfix gets a [Q], help gets [H]{base fname}
            -- others get 1dir/2dir/3dir/fname shortened to 1/2/3/fname
            local buftype = vim.fn.getbufvar(b, "&buftype")
            local bufname = vim.fn.bufname(b)

            if buftype == "help" then
                table.insert(n, "[H]" .. vim.fn.fnamemodify(bufname, ":t:s/.txt$//"))
            elseif buftype == "quickfix" then
                table.insert(n, "[Q]")
            elseif buftype == "terminal" then
                table.insert(n, "[T]" .. vim.fn.pathshorten(vim.split(bufname, "//")[2]))
            else
                local path = vim.fn.pathshorten(bufname)
                if string.len(path) > 0 then
                    table.insert(n, path)
                end
            end
            -- check and ++ tab's &modified count
            if vim.fn.getbufvar(b, "&modified") > 0 then
                m = m + 1
            end
            -- no final ' ' added...formatting looks better done later
            if bc > 1 then
                table.insert(n, " ")
            end
            bc = bc - 1
        end

        -- add modified label [n+] where n pages in tab are modified
        if m > 0 then
            table.insert(tab, string.format("[%d+]", m))
            table.insert(tabtext, string.format("[%d+]", m))
        end
        -- select the highlighting for the buffer names
        if t == vim.fn.tabpagenr() then
            table.insert(tab, "%#TabLineSel#")
        else
            table.insert(tab, "%#TabLine#")
        end
        -- add buffer names
        if #n == 0 then
            table.insert(tab, "[New]")
            table.insert(tabtext, "[New]")
        else
            table.insert(tab, table.concat(n, ""))
            table.insert(tabtext, table.concat(n, ""))
        end

        table.insert(tab, " ")
        table.insert(tabtext, " ")
        table.insert(tabline, table.concat(tab, ""))
        table.insert(tabtexts, table.concat(tabtext, ""))
    end

    -- modify if too long
    local prefix = ""
    local suffix = ""
    local tabstart = 1
    local tabend = vim.fn.tabpagenr("$")
    local tabpage = vim.fn.tabpagenr()

    print(vim.inspect(tabtexts))

    while string.len(table.concat(tabtexts, "")) + string.len(prefix) + string.len(suffix) > vim.go.columns do
        if tabend - tabpage > tabpage - tabstart then
            tabline = { unpack(tabline, 1, #tabline - 1) } -- delete one tab from right
            tabtexts = { unpack(tabtexts, 1, #tabtexts - 1) }
            suffix = "···"
            tabend = tabend - 1
        else
            tabline = { unpack(tabline, 2, #tabline) } -- delete one tab from left
            tabtexts = { unpack(tabtexts, 2, #tabtexts) }
            prefix = "···"
            tabstart = tabstart + 1
        end
    end

    tabline = { prefix, unpack(tabline) }
    table.insert(tabline, suffix)

    -- after the last tab fill with TabLineFill and reset tab page nr
    table.insert(tabline, "%#TabLineFill#%T")
    -- right-align the label to close the current tab page
    if vim.fn.tabpagenr("$") > 1 then
        table.insert(tabline, "%=%#TabLineFill#%999XX")
    end

    return table.concat(tabline, "")
end

vim.opt.tabline = "%!v:lua.tab_line()"
