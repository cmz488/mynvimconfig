require("bufferline").setup({
    options = {
        mode = "buffers",
        always_show_bufferline = true,
        show_buffer_close_icons = false,
        show_buffer_icons = true,
        diagnostics = "nvim_lsp",

        offsets = {
            {
                filetype = "NvimTree",
                text = "文件导航",
                separator = true,
            },
        },
    },
})
