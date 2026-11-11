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
        -- signature 继承 hover 的样式，位置单独修正：
        -- noice 的 anchor 是它自己的概念，nui 的 popup 根本不收 anchor 参数，
        -- 所以这里的 anchor/position 只是传给 nui 的 NW 锚点用，
        -- 真正的位置由下面 patch 的 update_options 按窗口高度算。
        signature = {
            view = "hover",
        },
    },
    lsp = {
        -- signature 用 noice 自己的视图，位置在下面的 patch 修正。
        signature = { view = "signature" },
    },
})

-- signature 浮窗定位修正。
-- noice 的 anchor 只是它自己的语义：nui 的 popup 不接受 anchor 参数，
-- 所以窗口总是按 NW 向下展开；而 get_layout 又会把 position.row 的负值
-- 当成「从屏幕底部算起的行号」，导致无论怎么配都靠不到光标边上。
-- 这里在布局算完后用窗口真实高度反推：让浮窗底边（含边框）
-- 恰好落在光标行的上一行。
local NuiView = require("noice.view.nui")
local update_options = NuiView.update_options
function NuiView:update_options()
    update_options(self)
    if self._opts.view ~= "signature" then
        return
    end
    local height = self._opts.size and self._opts.size.height
    if type(height) ~= "number" then
        return
    end
    self._opts.anchor = "NW"
    -- 上方能容下整个浮窗（内容 + 上下边框）就贴着光标行放，
    -- 否则退回下方，避免在文件顶部时盖住正在编辑的行。
    if vim.fn.winline() - 1 >= height + 2 then
        self._opts.position = { row = -(height + 1), col = 0 }
    else
        self._opts.position = { row = 2, col = 0 }
    end
end
