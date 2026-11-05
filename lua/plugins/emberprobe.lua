vim.pack.add({
    {
        src = "file:///home/cmz488/Projects/web_file/emberprobe",
        name = "emberprobe.nvim",
    },
}, { load = true })

require("emberprobe").setup({})
