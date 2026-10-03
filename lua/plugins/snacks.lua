vim.pack.add(
    {
        {
            src = "https://github.com/folke/snacks.nvim",
            version = "main",
        },
        { src = "https://github.com/folke/noice.nvim" },
        { src = "https://github.com/MunifTanjim/nui.nvim" },
    }
)


local sn = require("snacks")


sn.setup({


    -- 大文件优化
    bigfile = { enabled = true },

    -- 启动界面
    dashboard = require("plugins.dashboard"),

    -- 缩进参考线
    indent = { enabled = true },

    -- 输入框美化
    input = { enabled = true },

    -- 搜索工具
    picker = { enabled = true },

    -- 通知
    notifier = {
        enabled = true,
        timeout = 3000,
    },

    -- 文件快速加载
    quickfile = { enabled = true },


    -- 代码作用域
    scope = { enabled = true },

    -- LSP 引用高亮
    words = { enabled = true },

    -- 平滑滚动
    scroll = { enabled = true },
    image = {
        -- define these here, so that we don't need to load the image module
        formats = {
            "png",
            "jpg",
            "jpeg",
            "gif",
            "bmp",
            "webp",
            "tiff",
            "heic",
            "avif",
            "mp4",
            "mov",
            "avi",
            "mkv",
            "webm",
            "pdf",
            "icns",
        },
    },

})
require("noice").setup({
    cmdline = {
        enabled = true,
        view = "cmdline_popup",
    },

    messages = {
        enabled = false,
    },

    popupmenu = {
        enabled = true,
        backend = "nui",
    },

    presets = {
        command_palette = true,
        bottom_search = false,
        long_message_to_split = true,
    },
})
