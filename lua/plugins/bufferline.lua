local bufferline = require("bufferline")

-- 面板类 buffer 不进标签栏（NvimTree 由下面的 offsets 处理）
local hidden_filetypes = {
    lazy = true,
    mason = true,
    snacks_dashboard = true,
}

bufferline.setup({
    options = {
        mode = "buffers",
        always_show_bufferline = true,
        show_buffer_icons = true,
        color_icons = true,
        diagnostics = "nvim_lsp",

        -- 标签前显示序号，配合 <leader>1..9 直达第 N 个可见 buffer
        numbers = "ordinal",

        -- 关掉未选中 buffer 的粗体/斜体，只留文字，配合透明背景主题
        style_preset = bufferline.style_preset.minimal,

        -- 用下划线而不是色块标记当前 buffer，视觉更克制
        indicator = { style = "underline" },

        -- 单个 buffer 的关闭按钮只在鼠标悬停时出现，平时不占宽度
        show_buffer_close_icons = true,
        hover = {
            enabled = true,
            delay = 200,
            reveal = { "close" },
        },

        custom_filter = function(bufnr)
            return not hidden_filetypes[vim.bo[bufnr].filetype]
        end,

        -- 中键关闭走 core/buffers.lua：删除前先切窗口，焦点不会掉进 nvim-tree
        middle_mouse_command = function(bufnr)
            require("core.buffers").delete(bufnr)
        end,

        offsets = {
            {
                filetype = "NvimTree",
                text = "文件导航",
                separator = true,
            },
        },
    },
})