local tree = require("nvim-tree")

tree.setup({
    disable_netrw = true,
    hijack_netrw = true,

    -- 以目录作为参数启动时（nvim . / nvim ~/path）自动打开文件树。
    -- snacks dashboard 只在无参数启动时显示（dashboard.lua 中 argc(-1) > 0 会跳过），
    -- 所以目录参数的场景需要由 nvim-tree 来提供界面。
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
