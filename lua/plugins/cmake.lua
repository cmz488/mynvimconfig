vim.pack.add({
	{
		src = "https://github.com/nvim-lua/plenary.nvim"
	},
    {
        src = "https://github.com/Civitasv/cmake-tools.nvim"
    }
})

require("cmake-tools").setup({})
