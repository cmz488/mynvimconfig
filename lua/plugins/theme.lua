local cp = require("catppuccin")
local opts = {
    transparent_background = true,
    term_colors = true,
    integrations = {
        aerial = true,
        diffview = true,
        mini = {
            enabled = true,
            indentscope_color = "sky",
        },
        noice = true,
        -- overseer = true,
        telescope = {
            enabled = true,
            -- style = "nvchad",
        },
        treesitter = true,
        notify = true,
        gitsigns = true,
        flash = true,
        blink_cmp = true,
        mason = true,
        snacks = true,
    },
    highlight_overrides = {
        mocha = function(mocha)
            return {
                CursorLineNr = { fg = mocha.yellow },
                TelescopeSelection = { bg = mocha.surface0 },
                TelescopeSelectionCaret = { fg = mocha.yellow, bg = mocha.surface0 },
                TelescopePromptPrefix = { fg = mocha.yellow },
                FlashCurrent = { bg = mocha.peach, fg = mocha.base },
                FlashMatch = { bg = mocha.red, fg = mocha.base },
                FlashLabel = { bg = mocha.teal, fg = mocha.base },
                -- 与 transparent_background 对齐：浮窗背景透明，只留边框
                NormalFloat = { bg = "NONE" },
                FloatBorder = { fg = "#f0b8c0", bg = "NONE", style = { "bold" } },
                FloatTitle = { fg = "#f0b8c0", bg = "NONE", style = { "bold" } },
                -- 形参名提示只是辅助信息，不能和真实变量名争视觉。
                -- blend 让前景和底色混合，得到真正的半透明灰。
                LspInlayHint = { fg = "#a6adc8", bg = "NONE", blend = 50 },
                RenderMarkdownCode = { bg = mocha.crust },
                Pmenu = { bg = mocha.surface0 },
                Comment = { bg = nil },
                statusline = { bg = nil }
            }
        end,
    },
}

cp.setup(opts)
vim.cmd.colorscheme("catppuccin")

-- blink.cmp 在 ColorScheme 事件里用 nvim_set_hl{default=true} 设自己的高亮，
-- 会盖掉 highlight_overrides 里的同名定义（它执行得更晚）。
-- 这里在 colorscheme 之后重设一遍，并去掉 default 才能真覆盖。
-- 目的：补全菜单 / 文档 / 签名浮窗跟 hover 浮窗用同一套粉色边框 + 透明底。
vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("UserFloatStyle", { clear = true }),
    callback = function()
        local pink = "#f0b8c0"
        vim.api.nvim_set_hl(0, "BlinkCmpMenuBorder", { fg = pink, bg = "NONE", bold = true })
        vim.api.nvim_set_hl(0, "BlinkCmpMenu", { bg = "NONE" })
        vim.api.nvim_set_hl(0, "BlinkCmpDocBorder", { fg = pink, bg = "NONE", bold = true })
        vim.api.nvim_set_hl(0, "BlinkCmpDoc", { bg = "NONE" })
        vim.api.nvim_set_hl(0, "BlinkCmpSignatureHelpBorder", { fg = pink, bg = "NONE", bold = true })
        vim.api.nvim_set_hl(0, "BlinkCmpSignatureHelp", { bg = "NONE" })
    end,
})
-- 当前 session 已经加载完 colorscheme，立即跑一次
vim.api.nvim_exec_autocmds("ColorScheme", {})
