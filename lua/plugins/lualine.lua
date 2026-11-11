-- 状态栏：单条全局栏，底色透明（与 transparent_background 一致），
-- 只在模式处保留一块柔和的色板，其余信息靠三级灰阶区分。
vim.o.laststatus = 3

local palette = {
    overlay0 = "#6c7086",
    overlay1 = "#7f849c",
    subtext0 = "#a6adc8",
    text = "#cdd6f4",
    blue = "#89b4fa",
    green = "#a6e3a1",
    mauve = "#cba6f7",
    red = "#f38ba8",
    peach = "#fab387",
    teal = "#94e2d5",
}

-- 胶囊底色 = 模式色混进中性深色。太高的比例会让色块抢眼，
-- 太低则和透明背景糊成一片。
local CHIP_BASE = "#1b1b27"
local CHIP_ALPHA = 0.2

local function hex2rgb(hex)
    hex = hex:gsub("#", "")
    return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
end

local function blend(fg, bg, alpha)
    local fr, fgg, fb = hex2rgb(fg)
    local br, bgg, bb = hex2rgb(bg)
    local function mix(a, b)
        return math.floor(a * alpha + b * (1 - alpha) + 0.5)
    end
    return string.format("#%02x%02x%02x", mix(fr, br), mix(fgg, bgg), mix(fb, bb))
end

local accents = {
    normal = palette.blue,
    insert = palette.green,
    visual = palette.mauve,
    replace = palette.red,
    command = palette.peach,
    terminal = palette.teal,
}

local chip = {}
for mode, accent in pairs(accents) do
    chip[mode] = blend(accent, CHIP_BASE, CHIP_ALPHA)
end

local function theme_mode(mode)
    return {
        a = { fg = accents[mode], bg = chip[mode], gui = "bold" },
        b = { fg = palette.subtext0, bg = "NONE" },
        c = { fg = palette.text, bg = "NONE" },
    }
end

local theme = {
    normal = theme_mode("normal"),
    insert = theme_mode("insert"),
    visual = theme_mode("visual"),
    replace = theme_mode("replace"),
    command = theme_mode("command"),
    terminal = theme_mode("terminal"),
    inactive = {
        a = { fg = palette.overlay0, bg = "NONE" },
        b = { fg = palette.overlay0, bg = "NONE" },
        c = { fg = palette.overlay0, bg = "NONE" },
    },
}

-- V-LINE -> V-Line，NORMAL -> Normal
local function titleize(label)
    return (label:lower():gsub("(%a)([%w]*)", function(a, b)
        return a:upper() .. b
    end))
end

require("lualine").setup({
    options = {
        theme = theme,
        globalstatus = true,
        icons_enabled = true,
        section_separators = { left = "", right = "" },
        component_separators = { left = "", right = "" },
        disabled_filetypes = { statusline = { "dashboard", "alpha" }, winbar = {} },
        refresh = { statusline = 100 },
    },
    sections = {
        lualine_a = {
            { "mode", fmt = titleize, padding = { left = 2, right = 2 } },
        },
        lualine_b = {
            { "branch", icon = "" },
            { "diff", symbols = { added = "+", modified = "~", removed = "-" } },
        },
        lualine_c = {
            { "filename", path = 0, symbols = { modified = " ●", readonly = " ", unnamed = "" } },
        },
        lualine_x = {
            {
                "diagnostics",
                sources = { "nvim_lsp" },
                colored = true,
                update_in_insert = false,
                symbols = { error = " ", warn = " ", info = " ", hint = "" },
            },
        },
        lualine_y = {
            { "filetype", icons_enabled = false },
            { "encoding", fmt = string.lower },
        },
        -- z 段在 lualine 里映射到主题的 a（模式色板），这里显式改回透明，
        -- 否则行号会顶着一块和模式胶囊同色的底。
        lualine_z = {
            { "location", color = { fg = palette.overlay1, bg = "NONE" } },
        },
    },
    inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { { "filename", path = 0 } },
        lualine_x = { "location" },
        lualine_y = {},
        lualine_z = {},
    },
    extensions = { "nvim-tree", "fzf", "nvim-dap-ui", "overseer" },
})
