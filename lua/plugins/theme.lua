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
