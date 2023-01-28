local undodir = os.getenv("VIM_UNDO_DIR")
if not vim.call("isdirectory", undodir) then
    vim.call("mkdir", undodir)
end

vim.o.undodir = undodir
vim.cmd("set undofile")
vim.cmd("set nobackup")
vim.o.backupcopy = "no"
vim.o.writebackup = false
vim.o.swapfile = true
