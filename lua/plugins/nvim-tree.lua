local tree = require("nvim-tree")

tree.setup({
    disable_netrw = true,
    hijack_netrw = true,

    hijack_directories = {
        enable = true,
        auto_open = true,
    },

    sync_root_with_cwd = true,
    respect_buf_cwd = true,

    view = {
        side = "left",
        width = 32,
    },

    renderer = {
        group_empty = true,
        highlight_git = true,
    },

    filters = {
        dotfiles = false,
    },
    actions = {
        open_file = {
            quit_on_open = false,
            resize_window = true,
        },
    }
})
