return {
    -- remove trailing newlines
    -- formatCommand = "sed ':a;/^[ \n]*$/{$d;N;ba}'",
    formatCommand = "rev",
    formatStdin = true
}
