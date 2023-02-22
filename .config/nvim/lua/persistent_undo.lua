local undodir = vim.fn.stdpath("state") .. "/undo//"
vim.fn.mkdir(undodir, "p")
vim.o.undodir = undodir
vim.o.undofile = true

local swapdir = vim.fn.stdpath("state") .. "/swap//"
vim.fn.mkdir(swapdir, "p")
vim.o.directory = swapdir
vim.o.swapfile = true

-- Don't need backup as we already have swap and persistent undo.
vim.o.backup = false
vim.o.writebackup = false
