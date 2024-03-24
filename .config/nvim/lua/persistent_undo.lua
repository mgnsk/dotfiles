local undodir = vim.fn.resolve(vim.fn.stdpath("state") .. "/undo/")
vim.fn.mkdir(undodir, "p")
vim.o.undodir = undodir
vim.o.undofile = true
vim.o.swapfile = false
vim.o.backup = false
