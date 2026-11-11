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
    picker = { enabled = true, presets = "telescope" },

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
        enabled = true,
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

    -- noice 自己接管了 vim.lsp.buf.hover / signatureHelp，
    -- 不走 vim.lsp.handlers，所以边框只能在这里配。
    -- 用 nui 自带的 rounded：JetBrains Maple Mono 的圆角（╭）本身是 light 粗细，
    -- 跟 heavy 直边（━ ┃）混搭会在接缝处断粗细，圆角就显得薄。
    -- padding 只用 1 格：再大文字就会和边框显得疏远。
    views = {
        hover = {
            border = {
                style = "rounded",
                padding = { top = 0, bottom = 0, left = 1, right = 1 },
            },
            -- 边框窗口的 Normal 也指向 NormalFloat，
            -- 不显式置空会留一层不透明的底色。
            win_options = { winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder" },
        },
        -- signature 继承 hover 的样式，只改位置：
        -- anchor = SW 让窗口的底边对齐光标，row = -1 再抬一行，
        -- 这样输入行本身不被遮住。
        -- （noice 默认 auto 锚点会把窗口放在光标下方，正好盖住正在编辑的行）
        signature = {
            view = "hover",
            anchor = "SW",
            position = { row = -1, col = 0 },
        },
    },
    lsp = {
        -- 默认 signature 会回退到 documentation.view（即 hover），
        -- 不显式指定的话上面 views.signature 的锚点不会生效。
        signature = { view = "signature" },
    },
})
