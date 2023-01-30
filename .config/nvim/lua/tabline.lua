function _G.tab_line()
    local tabline = {}
    local tc = vim.fn.tabpagenr("$")

    for t = 1, tc do
        -- set highlight
        if t == vim.fn.tabpagenr() then
            table.insert(tabline, "%#TabLineSel#")
        else
            table.insert(tabline, "%#TabLine#")
        end
        -- set the tab page number (for mouse clicks)
        table.insert(tabline, string.format("%%%dT ", t))
        -- set page number string
        table.insert(tabline, string.format("%d ", t))

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
            table.insert(tabline, string.format("[%d+]", m))
        end
        -- select the highlighting for the buffer names
        -- my default highlighting only underlines the active tab
        -- buffer names.
        if t == vim.fn.tabpagenr() then
            table.insert(tabline, "%#TabLineSel#")
        else
            table.insert(tabline, "%#TabLine#")
        end
        -- add buffer names
        if #n == 0 then
            table.insert(tabline, "[New]")
        else
            table.insert(tabline, table.concat(n, ""))
        end
        -- switch to no underlining and add final space to buffer list
        table.insert(tabline, " ")
    end

    -- after the last tab fill with TabLineFill and reset tab page nr
    table.insert(tabline, "%#TabLineFill#%T")
    -- right-align the label to close the current tab page
    if vim.fn.tabpagenr("$") > 1 then
        table.insert(tabline, "%=%#TabLineFill#%999Xclose")
    end

    return table.concat(tabline, "")
end

vim.opt.tabline = "%!v:lua.tab_line()"
