return {
	{
		"airblade/vim-gitgutter",
		event = "BufEnter",
	},
	{
		"tpope/vim-fugitive",
		cond = not not os.getenv("NVIM_DIFF"),
	},
}
