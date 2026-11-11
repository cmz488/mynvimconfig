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

    -- 树根跟随 cwd（core/autocmds.lua 会把 cwd 切到项目根）
    sync_root_with_cwd = true,
    respect_buf_cwd = true,

    -- 焦点落到别的文件时，在树里定位到它
    update_focused_file = {
        enable = true,
        update_root = {
            enable = true,
        },
    },
    -- 进入项目子目录时不把树根缩小到子目录，配合上面的 update_root 使用
    prefer_startup_root = true,

    view = {
        side = "left",
        -- 随窗口宽度自适应，不再固定 32 列
        width = {
            min = 24,
            max = 40,
            padding = 2,
        },
    },

    renderer = {
        group_empty = true,
        -- 1.x 里这些都是 "none" | "icon" | "name" | "all"；
        -- 旧版的布尔值会被 legacy 逻辑翻译成 "name"
        highlight_git = "all",
        highlight_diagnostics = "all",
    },

    -- 未保存标记、LSP 诊断图标都受各自 enable 开关控制，默认是关的
    modified = {
        enable = true,
    },
    diagnostics = {
        enable = true,
    },

    -- 树内 m 打的书签默认重启即丢，持久化到 stdpath("data")/nvim-tree-bookmarks.json
    bookmarks = {
        persist = true,
    },

    filters = {
        dotfiles = false,
    },
    actions = {
        open_file = {
            quit_on_open = false,
            resize_window = true,
        },
    },
})